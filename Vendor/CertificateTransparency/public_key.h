#pragma once

#import <Security/Security.h>
#include <string_view>

#include "crypto_bytestring.h"

namespace certificate_transparency {

class PublicKey;

struct ASN1Method {
  int pkey_id;
  uint8_t oid[9];
  uint8_t oid_len;

  int (*pub_decode)(PublicKey* out, CBS* params, CBS* key);
};

class PublicKey {
 public:
  enum Type {
    kEC,
    kRSA,
  };

  static PublicKey Parse(std::string_view data);

  PublicKey();
  PublicKey(Type type, SecKeyRef key);
  PublicKey(const PublicKey&) = delete;
  PublicKey(PublicKey&& other);
  PublicKey& operator=(const PublicKey&) = delete;
  PublicKey& operator=(PublicKey&& rhs);

  ~PublicKey();

  Type type() const { return type_; }
  bool IsValid() const;
  bool VerifySignature(std::string_view data, std::string_view signature) const;

 private:
  Type type_ = kEC;
  SecKeyRef key_ = nullptr;
};

}  // namespace certificate_transparency
