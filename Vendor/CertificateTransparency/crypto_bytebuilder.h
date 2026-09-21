/* Copyright (c) 2014, Google Inc.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. */

#pragma once

#include <cstddef>
#include <cstdint>

#include "internal_types.h"

namespace certificate_transparency {

// CRYPTO ByteBuilder.
//
// |CBB| objects allow one to build length-prefixed serialisations. A |CBB|
// object is associated with a buffer and new buffers are created with
// |CBB_init|. Several |CBB| objects can point at the same buffer when a
// length-prefix is pending, however only a single |CBB| can be 'current' at
// any one time. For example, if one calls |CBB_add_u8_length_prefixed| then
// the new |CBB| points at the same buffer as the original. But if the original
// |CBB| is used then the length prefix is written out and the new |CBB| must
// not be used again.
//
// If one needs to force a length prefix to be written out because a |CBB| is
// going out of scope, use |CBB_flush|. If an operation on a |CBB| fails, it is
// in an undefined state and must not be used except to call |CBB_cleanup|.

struct cbb_buffer_st {
  uint8_t* buf;
  size_t len;      // The number of valid bytes.
  size_t cap;      // The size of buf.
  char can_resize; /* One iff |buf| is owned by this object. If not then |buf|
                      cannot be resized. */
  char error;      /* One iff there was an error writing to this CBB. All future
                      operations will fail. */
};

struct CBB {
  struct cbb_buffer_st* base;
  // child points to a child CBB if a length-prefix is pending.
  CBB* child;
  // offset is the number of bytes from the start of |base->buf| to this |CBB|'s
  // pending length prefix.
  size_t offset;
  // pending_len_len contains the number of bytes in this |CBB|'s pending
  // length-prefix, or zero if no length-prefix is pending.
  uint8_t pending_len_len;
  char pending_is_asn1;
  // is_child is true iff this is a child |CBB| (as opposed to a top-level
  // |CBB|). Top-level objects are valid arguments for |CBB_finish|.
  char is_child;
};

// CBB_zero sets an uninitialised |cbb| to the zero state. It must be
// initialised with |CBB_init| or |CBB_init_fixed| before use, but it is safe to
// call |CBB_cleanup| without a successful |CBB_init|. This may be used for more
// uniform cleanup of a |CBB|.
void CBB_zero(CBB* cbb);

// CBB_init initialises |cbb| with |initial_capacity|. Since a |CBB| grows as
// needed, the |initial_capacity| is just a hint. It returns one on success or
// zero on allocation failure.
int CBB_init(CBB* cbb, size_t initial_capacity);

// CBB_init_fixed initialises |cbb| to write to |len| bytes at |buf|. Since
// |buf| cannot grow, trying to write more than |len| bytes will cause CBB
// functions to fail. It returns one on success or zero on error.
int CBB_init_fixed(CBB* cbb, uint8_t* buf, size_t len);

// CBB_cleanup frees all resources owned by |cbb| and other |CBB| objects
// writing to the same buffer. This should be used in an error case where a
// serialisation is abandoned.
//
// This function can only be called on a "top level" |CBB|, i.e. one initialised
// with |CBB_init| or |CBB_init_fixed|, or a |CBB| set to the zero state with
// |CBB_zero|.
void CBB_cleanup(CBB* cbb);

// CBB_finish completes any pending length prefix and sets |*out_data| to a
// malloced buffer and |*out_len| to the length of that buffer. The caller
// takes ownership of the buffer and, unless the buffer was fixed with
// |CBB_init_fixed|, must call |OPENSSL_free| when done.
//
// It can only be called on a "top level" |CBB|, i.e. one initialised with
// |CBB_init| or |CBB_init_fixed|. It returns one on success and zero on
// error.
int CBB_finish(CBB* cbb, uint8_t** out_data, size_t* out_len);

// CBB_flush causes any pending length prefixes to be written out and any child
// |CBB| objects of |cbb| to be invalidated. This allows |cbb| to continue to be
// used after the children go out of scope, e.g. when local |CBB| objects are
// added as children to a |CBB| that persists after a function returns. This
// function returns one on success or zero on error.
int CBB_flush(CBB* cbb);

// CBB_data returns a pointer to the bytes written to |cbb|. It does not flush
// |cbb|. The pointer is valid until the next operation to |cbb|.
//
// To avoid unfinalized length prefixes, it is a fatal error to call this on a
// CBB with any active children.
const uint8_t* CBB_data(const CBB* cbb);

// CBB_len returns the number of bytes written to |cbb|. It does not flush
// |cbb|.
//
// To avoid unfinalized length prefixes, it is a fatal error to call this on a
// CBB with any active children.
size_t CBB_len(const CBB* cbb);

// CBB_add_u8_length_prefixed sets |*out_contents| to a new child of |cbb|. The
// data written to |*out_contents| will be prefixed in |cbb| with an 8-bit
// length. It returns one on success or zero on error.
int CBB_add_u8_length_prefixed(CBB* cbb, CBB* out_contents);

// CBB_add_u16_length_prefixed sets |*out_contents| to a new child of |cbb|.
// The data written to |*out_contents| will be prefixed in |cbb| with a 16-bit,
// big-endian length. It returns one on success or zero on error.
int CBB_add_u16_length_prefixed(CBB* cbb, CBB* out_contents);

// CBB_add_u24_length_prefixed sets |*out_contents| to a new child of |cbb|.
// The data written to |*out_contents| will be prefixed in |cbb| with a 24-bit,
// big-endian length. It returns one on success or zero on error.
int CBB_add_u24_length_prefixed(CBB* cbb, CBB* out_contents);

// CBB_add_asn1 sets |*out_contents| to a |CBB| into which the contents of an
// ASN.1 object can be written. The |tag| argument will be used as the tag for
// the object. It returns one on success or zero on error.
int CBB_add_asn1(CBB* cbb, CBB* out_contents, unsigned tag);

// CBB_add_bytes appends |len| bytes from |data| to |cbb|. It returns one on
// success and zero otherwise.
int CBB_add_bytes(CBB* cbb, const uint8_t* data, size_t len);

// CBB_add_zeros append |len| bytes with value zero to |cbb|. It returns one on
// success and zero otherwise.
int CBB_add_zeros(CBB* cbb, size_t len);

// CBB_add_space appends |len| bytes to |cbb| and sets |*out_data| to point to
// the beginning of that space. The caller must then write |len| bytes of
// actual contents to |*out_data|. It returns one on success and zero
// otherwise.
int CBB_add_space(CBB* cbb, uint8_t** out_data, size_t len);

// CBB_reserve ensures |cbb| has room for |len| additional bytes and sets
// |*out_data| to point to the beginning of that space. It returns one on
// success and zero otherwise. The caller may write up to |len| bytes to
// |*out_data| and call |CBB_did_write| to complete the write. |*out_data| is
// valid until the next operation on |cbb| or an ancestor |CBB|.
int CBB_reserve(CBB* cbb, uint8_t** out_data, size_t len);

// CBB_did_write advances |cbb| by |len| bytes, assuming the space has been
// written to by the caller. It returns one on success and zero on error.
int CBB_did_write(CBB* cbb, size_t len);

// CBB_add_u8 appends an 8-bit number from |value| to |cbb|. It returns one on
// success and zero otherwise.
int CBB_add_u8(CBB* cbb, uint8_t value);

// CBB_add_u16 appends a 16-bit, big-endian number from |value| to |cbb|. It
// returns one on success and zero otherwise.
int CBB_add_u16(CBB* cbb, uint16_t value);

// CBB_add_u16le appends a 16-bit, little-endian number from |value| to |cbb|.
// It returns one on success and zero otherwise.
int CBB_add_u16le(CBB* cbb, uint16_t value);

// CBB_add_u24 appends a 24-bit, big-endian number from |value| to |cbb|. It
// returns one on success and zero otherwise.
int CBB_add_u24(CBB* cbb, uint32_t value);

// CBB_add_u32 appends a 32-bit, big-endian number from |value| to |cbb|. It
// returns one on success and zero otherwise.
int CBB_add_u32(CBB* cbb, uint32_t value);

// CBB_add_u32le appends a 32-bit, little-endian number from |value| to |cbb|.
// It returns one on success and zero otherwise.
int CBB_add_u32le(CBB* cbb, uint32_t value);

// CBB_add_u64 appends a 64-bit, big-endian number from |value| to |cbb|. It
// returns one on success and zero otherwise.
int CBB_add_u64(CBB* cbb, uint64_t value);

// CBB_add_u64le appends a 64-bit, little-endian number from |value| to |cbb|.
// It returns one on success and zero otherwise.
int CBB_add_u64le(CBB* cbb, uint64_t value);

// CBB_discard_child discards the current unflushed child of |cbb|. Neither the
// child's contents nor the length prefix will be included in the output.
void CBB_discard_child(CBB* cbb);

// CBB_add_asn1_uint64 writes an ASN.1 INTEGER into |cbb| using |CBB_add_asn1|
// and writes |value| in its contents. It returns one on success and zero on
// error.
int CBB_add_asn1_uint64(CBB* cbb, uint64_t value);

// CBB_add_asn1_int64 writes an ASN.1 INTEGER into |cbb| using |CBB_add_asn1|
// and writes |value| in its contents. It returns one on success and zero on
// error.
int CBB_add_asn1_int64(CBB* cbb, int64_t value);

// CBB_add_asn1_octet_string writes an ASN.1 OCTET STRING into |cbb| with the
// given contents. It returns one on success and zero on error.
int CBB_add_asn1_octet_string(CBB* cbb, const uint8_t* data, size_t data_len);

// CBB_add_asn1_bool writes an ASN.1 BOOLEAN into |cbb| which is true iff
// |value| is non-zero.  It returns one on success and zero on error.
int CBB_add_asn1_bool(CBB* cbb, int value);

// CBB_add_asn1_oid_from_text decodes |len| bytes from |text| as an ASCII OID
// representation, e.g. "1.2.840.113554.4.1.72585", and writes the DER-encoded
// contents to |cbb|. It returns one on success and zero on malloc failure or if
// |text| was invalid. It does not include the OBJECT IDENTIFER framing, only
// the element's contents.
//
// This function considers OID strings with components which do not fit in a
// |uint64_t| to be invalid.
int CBB_add_asn1_oid_from_text(CBB* cbb, const char* text, size_t len);

// CBB_flush_asn1_set_of calls |CBB_flush| on |cbb| and then reorders the
// contents for a DER-encoded ASN.1 SET OF type. It returns one on success and
// zero on failure. DER canonicalizes SET OF contents by sorting
// lexicographically by encoding. Call this function when encoding a SET OF
// type in an order that is not already known to be canonical.
//
// Note a SET type has a slightly different ordering than a SET OF.
int CBB_flush_asn1_set_of(CBB* cbb);

using ScopedCBB = internal::StackAllocated<CBB, void, CBB_zero, CBB_cleanup>;

}  // namespace certificate_transparency
