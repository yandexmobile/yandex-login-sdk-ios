#pragma once

#include <cstdlib>
#include <memory>

namespace certificate_transparency {
namespace internal {

template <typename T>
struct Deleter;

template <>
struct Deleter<uint8_t> {
  void operator()(uint8_t* ptr) { free(ptr); }
};

template <typename T,
          typename CleanupRet,
          void (*init)(T*),
          CleanupRet (*cleanup)(T*)>
class StackAllocated {
 public:
  StackAllocated() { init(&ctx_); }
  ~StackAllocated() { cleanup(&ctx_); }

  StackAllocated(const StackAllocated&) = delete;
  StackAllocated& operator=(const StackAllocated&) = delete;

  T* get() { return &ctx_; }
  const T* get() const { return &ctx_; }

  T* operator->() { return &ctx_; }
  const T* operator->() const { return &ctx_; }

  void Reset() {
    cleanup(&ctx_);
    init(&ctx_);
  }

 private:
  T ctx_;
};

}  // namespace internal

template <typename T>
using UniquePtr = std::unique_ptr<T, internal::Deleter<T>>;

}  // namespace certificate_transparency
