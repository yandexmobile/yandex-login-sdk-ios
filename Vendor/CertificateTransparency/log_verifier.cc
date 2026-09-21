#include "log_verifier.h"

#include <CommonCrypto/CommonDigest.h>

namespace certificate_transparency {

LogVerifier::LogVerifier(std::string_view public_key)
    : key_(PublicKey::Parse(public_key)) {
  if (!key_.IsValid()) {
    return;
  }

  uint8_t key_id[32];
  CC_SHA256(public_key.data(), public_key.size(), key_id);
  key_id_.assign(std::begin(key_id), std::end(key_id));

  switch (key_.type()) {
    case PublicKey::kEC:
      hash_algorithm_ = DigitallySigned::HASH_ALGO_SHA256;
      signature_algorithm_ = DigitallySigned::SIG_ALGO_ECDSA;
      break;
    case PublicKey::kRSA:
      hash_algorithm_ = DigitallySigned::HASH_ALGO_SHA256;
      signature_algorithm_ = DigitallySigned::SIG_ALGO_RSA;
      break;
  }
}

LogVerifier::LogVerifier(LogVerifier&& other) = default;
LogVerifier& LogVerifier::operator=(LogVerifier&& rhs) = default;

LogVerifier::~LogVerifier() = default;

bool LogVerifier::IsValid() const {
  return key_.IsValid();
}

bool LogVerifier::Verify(const SignedEntryData& entry,
                         const SignedCertificateTimestamp& sct) const {
  std::string serialized_log_entry;
  std::string serialized_data;

  return IsValid() && sct.log_id == key_id_ &&
         SignatureParametersMatch(sct.signature) &&
         EncodeSignedEntry(entry, &serialized_log_entry) &&
         EncodeV1SCTSignedData(sct.timestamp, serialized_log_entry,
                               sct.extensions, &serialized_data) &&
         key_.VerifySignature(serialized_data, sct.signature.signature_data);
}

bool LogVerifier::SignatureParametersMatch(
    const DigitallySigned& signature) const {
  return signature.SignatureParametersMatch(hash_algorithm_,
                                            signature_algorithm_);
}

}  // namespace certificate_transparency
