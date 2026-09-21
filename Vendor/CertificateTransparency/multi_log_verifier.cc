#include "multi_log_verifier.h"

#include <algorithm>

namespace certificate_transparency {

MultiLogVerifier::MultiLogVerifier(const std::vector<std::string>& logs) {
  logs_.reserve(logs.size());
  for (const auto& log : logs) {
    LogVerifier verifier(log);
    if (!verifier.IsValid()) {
      continue;
    }

    std::string key_id = verifier.key_id();
    logs_.emplace_back(std::move(key_id), std::move(verifier));
  }
  std::sort(logs_.begin(), logs_.end(), [](const auto& lhs, const auto& rhs) {
    return lhs.first < rhs.first;
  });
}

MultiLogVerifier::~MultiLogVerifier() = default;

bool MultiLogVerifier::Verify(std::string_view leaf_cert,
                              std::string_view issuer_cert,
                              uint64_t now) const {
  if (logs_.empty()) {
    return true;
  }

  SignedEntryData data;
  std::string encoded_sct_list;
  std::vector<std::string_view> sct_list;
  if (!ExtractEmbeddedSCTList(leaf_cert, &encoded_sct_list) ||
      !GetPrecertSignedEntry(leaf_cert, issuer_cert, &data) ||
      !DecodeSCTList(encoded_sct_list, &sct_list)) {
    return false;
  }

  std::vector<std::string_view> embedded_log_ids;
  for (auto sct : sct_list) {
    SignedCertificateTimestamp decoded_sct;
    if (!DecodeSignedCertificateTimestamp(&sct, &decoded_sct)) {
      continue;
    }

    auto it = std::lower_bound(
        logs_.begin(), logs_.end(), decoded_sct.log_id,
        [](const auto& lhs, const auto& rhs) { return lhs.first < rhs; });
    if (it == logs_.end() || it->first != decoded_sct.log_id) {
      continue;
    }
    if (!it->second.Verify(data, decoded_sct)) {
      continue;
    }
    if (decoded_sct.timestamp > now) {
      continue;
    }

    embedded_log_ids.push_back(it->first);
  }

  std::sort(embedded_log_ids.begin(), embedded_log_ids.end());
  embedded_log_ids.erase(
      std::unique(embedded_log_ids.begin(), embedded_log_ids.end()),
      embedded_log_ids.end());

  return embedded_log_ids.size() >= std::min(2ul, logs_.size());
}

}  // namespace certificate_transparency
