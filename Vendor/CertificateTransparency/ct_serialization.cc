#include "ct_serialization.h"

#include "crypto_bytebuilder.h"
#include "crypto_bytestring.h"

namespace certificate_transparency {
namespace {

const size_t kLogIdLength = 32;

bool ReadSCTList(CBS* in, std::vector<std::string_view>* out) {
  std::vector<std::string_view> result;

  CBS sct_list_data;

  if (!CBS_get_u16_length_prefixed(in, &sct_list_data)) {
    return false;
  }

  while (CBS_len(&sct_list_data) != 0) {
    CBS sct_list_item;
    if (!CBS_get_u16_length_prefixed(&sct_list_data, &sct_list_item) ||
        CBS_len(&sct_list_item) == 0) {
      return false;
    }

    result.emplace_back(reinterpret_cast<const char*>(CBS_data(&sct_list_item)),
                        CBS_len(&sct_list_item));
  }

  result.swap(*out);
  return true;
}

bool ReadTimeSinceEpoch(CBS* input, uint64_t* time_since_epoch) {
  if (!CBS_get_u64(input, time_since_epoch)) {
    return false;
  }
  return true;
}

bool ConvertHashAlgorithm(unsigned in, DigitallySigned::HashAlgorithm* out) {
  switch (in) {
    case DigitallySigned::HASH_ALGO_NONE:
    case DigitallySigned::HASH_ALGO_MD5:
    case DigitallySigned::HASH_ALGO_SHA1:
    case DigitallySigned::HASH_ALGO_SHA224:
    case DigitallySigned::HASH_ALGO_SHA256:
    case DigitallySigned::HASH_ALGO_SHA384:
    case DigitallySigned::HASH_ALGO_SHA512:
      break;
    default:
      return false;
  }
  *out = static_cast<DigitallySigned::HashAlgorithm>(in);
  return true;
}

bool ConvertSignatureAlgorithm(unsigned in,
                               DigitallySigned::SignatureAlgorithm* out) {
  switch (in) {
    case DigitallySigned::SIG_ALGO_ANONYMOUS:
    case DigitallySigned::SIG_ALGO_RSA:
    case DigitallySigned::SIG_ALGO_DSA:
    case DigitallySigned::SIG_ALGO_ECDSA:
      break;
    default:
      return false;
  }
  *out = static_cast<DigitallySigned::SignatureAlgorithm>(in);
  return true;
}

bool DecodeDigitallySigned(CBS* input, DigitallySigned* output) {
  uint8_t hash_algo;
  uint8_t sig_algo;
  CBS sig_data;

  if (!CBS_get_u8(input, &hash_algo) || !CBS_get_u8(input, &sig_algo) ||
      !CBS_get_u16_length_prefixed(input, &sig_data)) {
    return false;
  }

  DigitallySigned result;
  if (!ConvertHashAlgorithm(hash_algo, &result.hash_algorithm) ||
      !ConvertSignatureAlgorithm(sig_algo, &result.signature_algorithm)) {
    return false;
  }

  result.signature_data.assign(
      reinterpret_cast<const char*>(CBS_data(&sig_data)), CBS_len(&sig_data));

  *output = result;
  return true;
}

bool EncodePrecertSignedEntry(const SignedEntryData& input, CBB* output) {
  CBB child;
  return CBB_add_bytes(output, input.issuer_key_hash.data(), kLogIdLength) &&
         CBB_add_u24_length_prefixed(output, &child) &&
         CBB_add_bytes(
             &child,
             reinterpret_cast<const uint8_t*>(input.tbs_certificate.data()),
             input.tbs_certificate.size()) &&
         CBB_flush(output);
}

bool EncodeSignedEntry(const SignedEntryData& input, CBB* output) {
  constexpr uint16_t kLogEntryTypePrecert = 1;
  if (!CBB_add_u16(output, kLogEntryTypePrecert)) {
    return false;
  }
  return EncodePrecertSignedEntry(input, output);
}

bool WriteTimeSinceEpoch(uint64_t timestamp, CBB* output) {
  return CBB_add_u64(output, timestamp);
}

}  // namespace

DigitallySigned::DigitallySigned() = default;
DigitallySigned::~DigitallySigned() = default;

bool DigitallySigned::SignatureParametersMatch(
    HashAlgorithm other_hash_algorithm,
    SignatureAlgorithm other_signature_algorithm) const {
  return (hash_algorithm == other_hash_algorithm) &&
         (signature_algorithm == other_signature_algorithm);
}

SignedCertificateTimestamp::SignedCertificateTimestamp() = default;
SignedCertificateTimestamp::~SignedCertificateTimestamp() = default;

bool DecodeSCTList(std::string_view input,
                   std::vector<std::string_view>* output) {
  std::vector<std::string_view> result;
  CBS input_cbs;
  CBS_init(&input_cbs, reinterpret_cast<const uint8_t*>(input.data()),
           input.size());
  if (!ReadSCTList(&input_cbs, &result) || CBS_len(&input_cbs) != 0 ||
      result.empty()) {
    return false;
  }

  output->swap(result);
  return true;
}

bool DecodeSignedCertificateTimestamp(std::string_view* input,
                                      SignedCertificateTimestamp* output) {
  uint8_t version;
  CBS input_cbs;
  CBS_init(&input_cbs, reinterpret_cast<const uint8_t*>(input->data()),
           input->size());
  if (!CBS_get_u8(&input_cbs, &version) ||
      version != SignedCertificateTimestamp::V1) {
    return false;
  }

  output->version = SignedCertificateTimestamp::V1;
  CBS log_id;
  CBS extensions;
  if (!CBS_get_bytes(&input_cbs, &log_id, kLogIdLength) ||
      !ReadTimeSinceEpoch(&input_cbs, &output->timestamp) ||
      !CBS_get_u16_length_prefixed(&input_cbs, &extensions) ||
      !DecodeDigitallySigned(&input_cbs, &output->signature)) {
    return false;
  }

  output->log_id.assign(reinterpret_cast<const char*>(CBS_data(&log_id)),
                        CBS_len(&log_id));
  output->extensions.assign(
      reinterpret_cast<const char*>(CBS_data(&extensions)),
      CBS_len(&extensions));
  input->remove_prefix(input->size() - CBS_len(&input_cbs));
  return true;
}

bool EncodeSignedEntry(const SignedEntryData& input, std::string* output) {
  ScopedCBB output_cbb;

  if (!CBB_init(output_cbb.get(), 64) ||
      !EncodeSignedEntry(input, output_cbb.get()) ||
      !CBB_flush(output_cbb.get())) {
    return false;
  }

  output->append(reinterpret_cast<const char*>(CBB_data(output_cbb.get())),
                 CBB_len(output_cbb.get()));
  return true;
}

bool EncodeV1SCTSignedData(uint64_t timestamp,
                           std::string_view serialized_log_entry,
                           std::string_view extensions,
                           std::string* output) {
  constexpr uint8_t SIGNATURE_TYPE_CERTIFICATE_TIMESTAMP = 0;

  ScopedCBB output_cbb;
  CBB child;
  if (!CBB_init(output_cbb.get(), 64) ||
      !CBB_add_u8(output_cbb.get(), SignedCertificateTimestamp::V1) ||
      !CBB_add_u8(output_cbb.get(), SIGNATURE_TYPE_CERTIFICATE_TIMESTAMP) ||
      !WriteTimeSinceEpoch(timestamp, output_cbb.get()) ||
      // NOTE: serialized_log_entry must already be serialized and contain the
      // length as the prefix.
      !CBB_add_bytes(
          output_cbb.get(),
          reinterpret_cast<const uint8_t*>(serialized_log_entry.data()),
          serialized_log_entry.size()) ||
      !CBB_add_u16_length_prefixed(output_cbb.get(), &child) ||
      !CBB_add_bytes(&child,
                     reinterpret_cast<const uint8_t*>(extensions.data()),
                     extensions.size()) ||
      !CBB_flush(output_cbb.get())) {
    return false;
  }
  output->append(reinterpret_cast<const char*>(CBB_data(output_cbb.get())),
                 CBB_len(output_cbb.get()));
  return true;
}

}  // namespace certificate_transparency
