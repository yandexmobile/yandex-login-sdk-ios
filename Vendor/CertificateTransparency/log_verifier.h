#pragma once

#include <string>
#include <string_view>

#include "ct_objects_extractor.h"
#include "ct_serialization.h"
#include "public_key.h"

namespace certificate_transparency {

class LogVerifier {
 public:
  explicit LogVerifier(std::string_view public_key);
  LogVerifier(LogVerifier&& other);
  LogVerifier& operator=(LogVerifier&& rhs);
  ~LogVerifier();

  bool IsValid() const;
  const std::string& key_id() const { return key_id_; }

  bool Verify(const SignedEntryData& entry,
              const SignedCertificateTimestamp& sct) const;

 private:
  bool SignatureParametersMatch(const DigitallySigned& signature) const;

  PublicKey key_;
  std::string key_id_;
  DigitallySigned::HashAlgorithm hash_algorithm_ =
      DigitallySigned::HASH_ALGO_NONE;
  DigitallySigned::SignatureAlgorithm signature_algorithm_ =
      DigitallySigned::SIG_ALGO_ANONYMOUS;
};

}  // namespace certificate_transparency
