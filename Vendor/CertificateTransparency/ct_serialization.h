#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "ct_objects_extractor.h"

namespace certificate_transparency {

struct DigitallySigned {
  enum HashAlgorithm {
    HASH_ALGO_NONE = 0,
    HASH_ALGO_MD5 = 1,
    HASH_ALGO_SHA1 = 2,
    HASH_ALGO_SHA224 = 3,
    HASH_ALGO_SHA256 = 4,
    HASH_ALGO_SHA384 = 5,
    HASH_ALGO_SHA512 = 6,
  };

  enum SignatureAlgorithm {
    SIG_ALGO_ANONYMOUS = 0,
    SIG_ALGO_RSA = 1,
    SIG_ALGO_DSA = 2,
    SIG_ALGO_ECDSA = 3
  };

  DigitallySigned();
  ~DigitallySigned();

  // Returns true if |other_hash_algorithm| and |other_signature_algorithm|
  // match this DigitallySigned hash and signature algorithms.
  bool SignatureParametersMatch(
      HashAlgorithm other_hash_algorithm,
      SignatureAlgorithm other_signature_algorithm) const;

  HashAlgorithm hash_algorithm = HASH_ALGO_NONE;
  SignatureAlgorithm signature_algorithm = SIG_ALGO_ANONYMOUS;
  // 'signature' field.
  std::string signature_data;
};

struct SignedCertificateTimestamp {
  // Version enum in RFC 6962, Section 3.2.
  enum Version {
    V1 = 0,
  };

  SignedCertificateTimestamp();
  ~SignedCertificateTimestamp();

  Version version = V1;
  std::string log_id;
  uint64_t timestamp = 0;
  std::string extensions;
  DigitallySigned signature;
};

bool DecodeSCTList(std::string_view input,
                   std::vector<std::string_view>* output);

bool DecodeSignedCertificateTimestamp(std::string_view* input,
                                      SignedCertificateTimestamp* output);

bool EncodeSignedEntry(const SignedEntryData& input, std::string* output);

bool EncodeV1SCTSignedData(uint64_t timestamp,
                           std::string_view serialized_log_entry,
                           std::string_view extensions,
                           std::string* output);

}  // namespace certificate_transparency
