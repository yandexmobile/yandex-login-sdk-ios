#include "public_key.h"

#include <utility>

#include "crypto_bytestring.h"
#include "ec_public_key.h"
#include "rsa_public_key.h"
#include "safe_cstring.h"

namespace certificate_transparency {
namespace {

const ASN1Method* const kASN1Methods[] = {&kECASN1Method, &kRSAASN1Method};

const ASN1Method* ParseKeyMethod(CBS* cbs) {
  CBS oid;
  if (!CBS_get_asn1(cbs, &oid, CBS_ASN1_OBJECT)) {
    return nullptr;
  }

  for (const auto* method : kASN1Methods) {
    if (CBS_len(&oid) == method->oid_len &&
        safe_memcmp(CBS_data(&oid), method->oid, method->oid_len) == 0) {
      return method;
    }
  }

  return nullptr;
}

PublicKey ParsePublicKey(CBS* cbs) {
  CBS spki, algorithm, key;
  uint8_t padding;
  if (!CBS_get_asn1(cbs, &spki, CBS_ASN1_SEQUENCE) ||
      !CBS_get_asn1(&spki, &algorithm, CBS_ASN1_SEQUENCE) ||
      !CBS_get_asn1(&spki, &key, CBS_ASN1_BITSTRING) || CBS_len(&spki) != 0) {
    return {};
  }
  const ASN1Method* method = ParseKeyMethod(&algorithm);
  if (!method || !method->pub_decode) {
    return {};
  }
  if (!CBS_get_u8(&key, &padding) || padding != 0) {
    return {};
  }

  PublicKey result;
  if (!method->pub_decode(&result, &algorithm, &key)) {
    return {};
  }

  return result;
}

}  // namespace

PublicKey::PublicKey() = default;

PublicKey::PublicKey(Type type, SecKeyRef key) : type_(type), key_(key) {}

PublicKey::PublicKey(PublicKey&& other)
    : type_(other.type_), key_(std::exchange(other.key_, nullptr)) {}

PublicKey& PublicKey::operator=(PublicKey&& rhs) {
  std::swap(type_, rhs.type_);
  std::swap(key_, rhs.key_);
  return *this;
}

PublicKey::~PublicKey() {
  if (key_) {
    CFRelease(key_);
  }
}

// static
PublicKey PublicKey::Parse(std::string_view data) {
  CBS cbs;
  CBS_init(&cbs, reinterpret_cast<const uint8_t*>(data.data()), data.size());
  auto key = ParsePublicKey(&cbs);
  if (!key.IsValid() || CBS_len(&cbs) != 0) {
    return {};
  }

  return key;
}

bool PublicKey::IsValid() const {
  return key_ != nullptr;
}

bool PublicKey::VerifySignature(
    std::string_view data,
    std::string_view signature) const {
  assert(IsValid());

  SecKeyAlgorithm algorithm;
  switch (type_) {
    case kEC:
      algorithm = kSecKeyAlgorithmECDSASignatureMessageX962SHA256;
      break;
    case kRSA:
      algorithm = kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;
      break;
  }

  CFDataRef cfdata = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault, reinterpret_cast<const UInt8*>(data.data()),
      data.size(), kCFAllocatorNull);
  CFDataRef cfsignature = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault, reinterpret_cast<const UInt8*>(signature.data()),
      signature.size(), kCFAllocatorNull);
  bool result =
      SecKeyVerifySignature(key_, algorithm, cfdata, cfsignature, nullptr);
  CFRelease(cfsignature);
  CFRelease(cfdata);

  return result;
}

}  // namespace certificate_transparency
