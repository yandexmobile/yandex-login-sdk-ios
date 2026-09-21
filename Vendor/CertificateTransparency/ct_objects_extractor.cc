#include "ct_objects_extractor.h"

#include <CommonCrypto/CommonDigest.h>
#include <cassert>

#include "crypto_bytebuilder.h"
#include "crypto_bytestring.h"
#include "internal_types.h"

namespace certificate_transparency {
namespace {

// The wire form of the OID 1.3.6.1.4.1.11129.2.4.2. See Section 3.3 of
// RFC6962.
const uint8_t kEmbeddedSCTOid[] = {0x2B, 0x06, 0x01, 0x04, 0x01,
                                   0xD6, 0x79, 0x02, 0x04, 0x02};

bool SkipElements(CBS* cbs, int count) {
  for (int i = 0; i < count; ++i) {
    if (!CBS_get_any_asn1_element(cbs, nullptr, nullptr, nullptr))
      return false;
  }
  return true;
}

bool SkipOptionalElement(CBS* cbs, unsigned tag) {
  CBS unused;
  return !CBS_peek_asn1_tag(cbs, tag) || CBS_get_asn1(cbs, &unused, tag);
}

// Skips |tbs_cert|, which must be a TBSCertificate body, to just before the
// extensions element.
bool SkipTBSCertificateToExtensions(CBS* tbs_cert) {
  constexpr unsigned kVersionTag =
      CBS_ASN1_CONTEXT_SPECIFIC | CBS_ASN1_CONSTRUCTED | 0;
  constexpr unsigned kIssuerUniqueIDTag = CBS_ASN1_CONTEXT_SPECIFIC | 1;
  constexpr unsigned kSubjectUniqueIDTag = CBS_ASN1_CONTEXT_SPECIFIC | 2;
  return SkipOptionalElement(tbs_cert, kVersionTag) &&
         SkipElements(tbs_cert,
                      6 /* serialNumber through subjectPublicKeyInfo */) &&
         SkipOptionalElement(tbs_cert, kIssuerUniqueIDTag) &&
         SkipOptionalElement(tbs_cert, kSubjectUniqueIDTag);
}

// Copies all the bytes in |outer| which are before |inner| to |out|. |inner|
// must be a subset of |outer|.
bool CopyBefore(const CBS& outer, const CBS& inner, CBB* out) {
  return !!CBB_add_bytes(out, CBS_data(&outer),
                         CBS_data(&inner) - CBS_data(&outer));
}

// Copies all the bytes in |outer| which are after |inner| to |out|. |inner|
// must be a subset of |outer|.
bool CopyAfter(const CBS& outer, const CBS& inner, CBB* out) {
  return !!CBB_add_bytes(
      out, CBS_data(&inner) + CBS_len(&inner),
      CBS_data(&outer) + CBS_len(&outer) - CBS_data(&inner) - CBS_len(&inner));
}

bool FindExtensionElement(const CBS& extensions,
                          const uint8_t* oid,
                          size_t oid_len,
                          CBS* out) {
  CBS extensions_copy = extensions;
  CBS result;
  CBS_init(&result, nullptr, 0);
  bool found = false;
  while (CBS_len(&extensions_copy) > 0) {
    CBS extension_element;
    if (!CBS_get_asn1_element(&extensions_copy, &extension_element,
                              CBS_ASN1_SEQUENCE)) {
      return false;
    }

    CBS copy = extension_element;
    CBS extension, extension_oid;
    if (!CBS_get_asn1(&copy, &extension, CBS_ASN1_SEQUENCE) ||
        !CBS_get_asn1(&extension, &extension_oid, CBS_ASN1_OBJECT)) {
      return false;
    }

    if (CBS_mem_equal(&extension_oid, oid, oid_len)) {
      if (found)
        return false;
      found = true;
      result = extension_element;
    }
  }
  if (!found)
    return false;

  *out = result;
  return true;
}

bool ParseSCTListFromExtensions(const CBS& extensions,
                                const uint8_t* oid,
                                size_t oid_len,
                                std::string* out_sct_list) {
  CBS extension_element, extension, extension_oid, value, sct_list;
  if (!FindExtensionElement(extensions, oid, oid_len, &extension_element) ||
      !CBS_get_asn1(&extension_element, &extension, CBS_ASN1_SEQUENCE) ||
      !CBS_get_asn1(&extension, &extension_oid, CBS_ASN1_OBJECT) ||
      // Skip the optional critical element.
      !SkipOptionalElement(&extension, CBS_ASN1_BOOLEAN) ||
      // The extension value is stored in an OCTET STRING.
      !CBS_get_asn1(&extension, &value, CBS_ASN1_OCTETSTRING) ||
      CBS_len(&extension) != 0 ||
      // The extension value itself is an OCTET STRING containing the
      // serialized SCT list.
      !CBS_get_asn1(&value, &sct_list, CBS_ASN1_OCTETSTRING) ||
      CBS_len(&value) != 0) {
    return false;
  }

  assert(CBS_mem_equal(&extension_oid, oid, oid_len));
  *out_sct_list = std::string(
      reinterpret_cast<const char*>(CBS_data(&sct_list)), CBS_len(&sct_list));
  return true;
}

bool ExtractSPKIFromDERCert(std::string_view cert, std::string_view* spki_out) {
  CBS cert_cbs;
  CBS_init(&cert_cbs, reinterpret_cast<const uint8_t*>(cert.data()),
           cert.size());
  CBS cert_body, tbs_cert;
  if (!CBS_get_asn1(&cert_cbs, &cert_body, CBS_ASN1_SEQUENCE) ||
      CBS_len(&cert_cbs) != 0 ||
      !CBS_get_asn1(&cert_body, &tbs_cert, CBS_ASN1_SEQUENCE)) {
    return false;
  }

  constexpr unsigned kVersionTag =
      CBS_ASN1_CONTEXT_SPECIFIC | CBS_ASN1_CONSTRUCTED | 0;
  if (!SkipOptionalElement(&tbs_cert, kVersionTag) ||
      !SkipElements(&tbs_cert, 5)) {
    return false;
  }

  CBS spki_cbs;
  if (!CBS_get_any_asn1_element(&tbs_cert, &spki_cbs, nullptr, nullptr)) {
    return false;
  }

  *spki_out = std::string_view(
      reinterpret_cast<const char*>(CBS_data(&spki_cbs)), CBS_len(&spki_cbs));
  return true;
}

}  // namespace

SignedEntryData::SignedEntryData() = default;
SignedEntryData::~SignedEntryData() = default;

bool ExtractEmbeddedSCTList(std::string_view cert, std::string* sct_list) {
  CBS cert_cbs;
  CBS_init(&cert_cbs, reinterpret_cast<const uint8_t*>(cert.data()),
           cert.size());
  CBS cert_body, tbs_cert, extensions_wrap, extensions;
  if (!CBS_get_asn1(&cert_cbs, &cert_body, CBS_ASN1_SEQUENCE) ||
      CBS_len(&cert_cbs) != 0 ||
      !CBS_get_asn1(&cert_body, &tbs_cert, CBS_ASN1_SEQUENCE) ||
      !SkipTBSCertificateToExtensions(&tbs_cert) ||
      // Extract the extensions list.
      !CBS_get_asn1(&tbs_cert, &extensions_wrap,
                    CBS_ASN1_CONTEXT_SPECIFIC | CBS_ASN1_CONSTRUCTED | 3) ||
      !CBS_get_asn1(&extensions_wrap, &extensions, CBS_ASN1_SEQUENCE) ||
      CBS_len(&extensions_wrap) != 0 || CBS_len(&tbs_cert) != 0) {
    return false;
  }

  return ParseSCTListFromExtensions(extensions, kEmbeddedSCTOid,
                                    sizeof(kEmbeddedSCTOid), sct_list);
}

bool GetPrecertSignedEntry(std::string_view leaf,
                           std::string_view issuer,
                           SignedEntryData* result) {
  // Parse the TBSCertificate.
  CBS cert_cbs;
  CBS_init(&cert_cbs, reinterpret_cast<const uint8_t*>(leaf.data()),
           leaf.size());
  CBS cert_body, tbs_cert;
  if (!CBS_get_asn1(&cert_cbs, &cert_body, CBS_ASN1_SEQUENCE) ||
      CBS_len(&cert_cbs) != 0 ||
      !CBS_get_asn1(&cert_body, &tbs_cert, CBS_ASN1_SEQUENCE)) {
    return false;
  }

  CBS tbs_cert_copy = tbs_cert;
  if (!SkipTBSCertificateToExtensions(&tbs_cert)) {
    return false;
  }

  // Start filling in a new TBSCertificate. Copy everything parsed or skipped
  // so far to the |new_tbs_cert|.
  ScopedCBB cbb;
  CBB new_tbs_cert;
  if (!CBB_init(cbb.get(), CBS_len(&tbs_cert_copy)) ||
      !CBB_add_asn1(cbb.get(), &new_tbs_cert, CBS_ASN1_SEQUENCE) ||
      !CopyBefore(tbs_cert_copy, tbs_cert, &new_tbs_cert)) {
    return false;
  }

  // Parse the extensions list and find the SCT extension.
  constexpr unsigned kExtensionsTag =
      CBS_ASN1_CONTEXT_SPECIFIC | CBS_ASN1_CONSTRUCTED | 3;
  CBS extensions_wrap, extensions, sct_extension;
  if (!CBS_get_asn1(&tbs_cert, &extensions_wrap, kExtensionsTag) ||
      !CBS_get_asn1(&extensions_wrap, &extensions, CBS_ASN1_SEQUENCE) ||
      CBS_len(&extensions_wrap) != 0 || CBS_len(&tbs_cert) != 0 ||
      !FindExtensionElement(extensions, kEmbeddedSCTOid,
                            sizeof(kEmbeddedSCTOid), &sct_extension)) {
    return false;
  }

  // Add extensions to the TBSCertificate. Copy all extensions except the
  // embedded SCT extension.
  CBB new_extensions_wrap, new_extensions;
  if (!CBB_add_asn1(&new_tbs_cert, &new_extensions_wrap, kExtensionsTag) ||
      !CBB_add_asn1(&new_extensions_wrap, &new_extensions, CBS_ASN1_SEQUENCE) ||
      !CopyBefore(extensions, sct_extension, &new_extensions) ||
      !CopyAfter(extensions, sct_extension, &new_extensions)) {
    return false;
  }

  uint8_t* new_tbs_cert_der;
  size_t new_tbs_cert_len;
  if (!CBB_finish(cbb.get(), &new_tbs_cert_der, &new_tbs_cert_len)) {
    return false;
  }
  UniquePtr<uint8_t> scoped_new_tbs_cert_der(new_tbs_cert_der);

  // Extract the issuer's public key.
  std::string_view issuer_key;
  if (!ExtractSPKIFromDERCert(issuer, &issuer_key)) {
    return false;
  }

  // Fill in the SignedEntryData.
  CC_SHA256(issuer_key.data(), issuer_key.size(),
            result->issuer_key_hash.data());
  result->tbs_certificate.assign(
      reinterpret_cast<const char*>(new_tbs_cert_der), new_tbs_cert_len);

  return true;
}

}  // namespace certificate_transparency
