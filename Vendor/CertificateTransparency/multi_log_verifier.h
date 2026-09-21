#pragma once

#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "log_verifier.h"

namespace certificate_transparency {

class MultiLogVerifier {
 public:
  explicit MultiLogVerifier(const std::vector<std::string>& logs);
  ~MultiLogVerifier();

  bool Verify(std::string_view leaf_cert,
              std::string_view issuer_cert,
              uint64_t now) const;

 private:
  std::vector<std::pair<std::string, LogVerifier>> logs_;
};

}  // namespace certificate_transparency
