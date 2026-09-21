#include "ec_public_key.h"

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#include "crypto_bytestring.h"

namespace certificate_transparency {
namespace {

int DecodeECPublicKey(PublicKey* out, CBS* params, CBS* key) {
  CBS named_curve;
  if (!CBS_get_asn1(params, &named_curve, CBS_ASN1_OBJECT) ||
      CBS_len(params) != 0) {
    return 0;
  }

  const uint8_t* buf = CBS_data(key);
  size_t len = CBS_len(key);
  if (len % 2 == 0 || buf[0] != 4) {
    return 0;
  }

  CFDataRef data = CFDataCreate(kCFAllocatorDefault, buf, len);
  NSDictionary* attributes = @ {
    (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
    (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic
  };
  SecKeyRef public_key =
      SecKeyCreateWithData(data, (CFDictionaryRef)attributes, nullptr);
  CFRelease(data);

  if (public_key) {
    *out = PublicKey(PublicKey::kEC, public_key);
    return 1;
  } else {
    return 0;
  }
}

}  // namespace

const ASN1Method kECASN1Method = {
    PublicKey::kEC,
    // 1.2.840.10045.2.1
    {0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01},
    7,
    DecodeECPublicKey};

}  // namespace certificate_transparency
