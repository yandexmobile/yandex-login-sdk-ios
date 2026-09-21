#pragma once

#include <cstdlib>
#include <cstring>

namespace certificate_transparency {

static inline const uint8_t* safe_memchr(const uint8_t* s, int c, size_t n) {
  if (n == 0) {
    return NULL;
  }

  return reinterpret_cast<const uint8_t*>(memchr(s, c, n));
}

static inline void* safe_memcpy(void* dst, const void* src, size_t n) {
  if (n == 0) {
    return dst;
  }

  return memcpy(dst, src, n);
}

static inline int safe_memcmp(const void* s1, const void* s2, size_t n) {
  if (n == 0) {
    return 0;
  }

  return memcmp(s1, s2, n);
}

static inline void* safe_memset(void* dst, int c, size_t n) {
  if (n == 0) {
    return dst;
  }

  return memset(dst, c, n);
}

static inline void* safe_memmove(void* dst, const void* src, size_t n) {
  if (n == 0) {
    return dst;
  }

  return memmove(dst, src, n);
}

static inline void* safe_memdup(const void* data, size_t size) {
  if (size == 0) {
    return NULL;
  }

  void* ret = malloc(size);
  if (ret == NULL) {
    return NULL;
  }

  safe_memcpy(ret, data, size);
  return ret;
}

static inline int secure_memcmp(const void* in_a,
                                const void* in_b,
                                size_t len) {
  const uint8_t* a = reinterpret_cast<const uint8_t*>(in_a);
  const uint8_t* b = reinterpret_cast<const uint8_t*>(in_b);
  uint8_t x = 0;

  for (size_t i = 0; i < len; i++) {
    x |= a[i] ^ b[i];
  }

  return x;
}

}  // namespace certificate_transparency
