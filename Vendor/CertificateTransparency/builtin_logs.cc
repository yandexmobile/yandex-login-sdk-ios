#include "builtin_logs.h"

#include <algorithm>

namespace certificate_transparency {
namespace {

struct Item {
  const char* data;
  int len;
};

const Item kLogList[] = {
#include "builtin_logs-inc.h"
};

}  // namespace

std::vector<std::string> GetBuiltinLogs() {
  std::vector<std::string> result;
  result.reserve(std::size(kLogList));
  for (const auto& log : kLogList) {
    result.push_back(std::string(log.data, log.data + log.len));
  }
  return result;
}

}  // namespace certificate_transparency
