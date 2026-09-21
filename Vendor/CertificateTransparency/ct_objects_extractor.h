#pragma once

#include <array>
#include <string>
#include <string_view>

namespace certificate_transparency {

struct SignedEntryData {
  SignedEntryData();
  ~SignedEntryData();

  std::array<uint8_t, 32> issuer_key_hash;
  std::string tbs_certificate;
};

bool ExtractEmbeddedSCTList(std::string_view cert, std::string* sct_list);

bool GetPrecertSignedEntry(std::string_view leaf,
                           std::string_view issuer,
                           SignedEntryData* result);

}  // namespace certificate_transparency
