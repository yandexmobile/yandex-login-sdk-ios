#include "rsa_public_key.h"

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#include "crypto_bytestring.h"

namespace certificate_transparency {
namespace {

int DecodeRSAPublicKey(PublicKey* out, CBS* params, CBS* key) {
  // The parameters must be NULL.
  CBS null;
  if (!CBS_get_asn1(params, &null, CBS_ASN1_NULL) || CBS_len(&null) != 0 ||
      CBS_len(params) != 0) {
    return 0;
  }

  const uint8_t* buf = CBS_data(key);
  size_t len = CBS_len(key);
  CFDataRef data = CFDataCreate(kCFAllocatorDefault, buf, len);
  NSDictionary* attributes = @ {
    (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
    (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic
  };
  SecKeyRef public_key =
      SecKeyCreateWithData(data, (CFDictionaryRef)attributes, nullptr);
  CFRelease(data);

  if (public_key) {
    // Require RSA keys of at least 2048 bits.
    if (SecKeyGetBlockSize(public_key) < 256) {
      CFRelease(public_key);
      return 0;
    }
    *out = PublicKey(PublicKey::kRSA, public_key);
    return 1;
  } else {
    return 0;
  }
}

}  // namespace

const ASN1Method kRSAASN1Method = {
    PublicKey::kRSA,
    // 1.2.840.113549.1.1.1
    {0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01},
    9,
    DecodeRSAPublicKey};

}  // namespace certificate_transparency
