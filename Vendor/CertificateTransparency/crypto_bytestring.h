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

namespace certificate_transparency {

struct CBS {
  const uint8_t* data;
  size_t len;

  CBS() = default;
  CBS(const CBS&) = default;
  CBS& operator=(const CBS&) = default;
};

// CBS_init sets |cbs| to point to |data|. It does not take ownership of
// |data|.
void CBS_init(CBS* cbs, const uint8_t* data, size_t len);

// CBS_skip advances |cbs| by |len| bytes. It returns one on success and zero
// otherwise.
int CBS_skip(CBS* cbs, size_t len);

// CBS_data returns a pointer to the contents of |cbs|.
const uint8_t* CBS_data(const CBS* cbs);

// CBS_len returns the number of bytes remaining in |cbs|.
size_t CBS_len(const CBS* cbs);

// CBS_mem_equal compares the current contents of |cbs| with the |len| bytes
// starting at |data|. If they're equal, it returns one, otherwise zero. If the
// lengths match, it uses a constant-time comparison.
int CBS_mem_equal(const CBS* cbs, const uint8_t* data, size_t len);

// CBS_get_u8 sets |*out| to the next uint8_t from |cbs| and advances |cbs|. It
// returns one on success and zero on error.
int CBS_get_u8(CBS* cbs, uint8_t* out);

// CBS_get_u16 sets |*out| to the next, big-endian uint16_t from |cbs| and
// advances |cbs|. It returns one on success and zero on error.
int CBS_get_u16(CBS* cbs, uint16_t* out);

// CBS_get_u16le sets |*out| to the next, little-endian uint16_t from |cbs| and
// advances |cbs|. It returns one on success and zero on error.
int CBS_get_u16le(CBS* cbs, uint16_t* out);

// CBS_get_u24 sets |*out| to the next, big-endian 24-bit value from |cbs| and
// advances |cbs|. It returns one on success and zero on error.
int CBS_get_u24(CBS* cbs, uint32_t* out);

// CBS_get_u32 sets |*out| to the next, big-endian uint32_t value from |cbs|
// and advances |cbs|. It returns one on success and zero on error.
int CBS_get_u32(CBS* cbs, uint32_t* out);

// CBS_get_u32le sets |*out| to the next, little-endian uint32_t value from
// |cbs| and advances |cbs|. It returns one on success and zero on error.
int CBS_get_u32le(CBS* cbs, uint32_t* out);

// CBS_get_u64 sets |*out| to the next, big-endian uint64_t value from |cbs|
// and advances |cbs|. It returns one on success and zero on error.
int CBS_get_u64(CBS* cbs, uint64_t* out);

// CBS_get_u64le sets |*out| to the next, little-endian uint64_t value from
// |cbs| and advances |cbs|. It returns one on success and zero on error.
int CBS_get_u64le(CBS* cbs, uint64_t* out);

// CBS_get_last_u8 sets |*out| to the last uint8_t from |cbs| and shortens
// |cbs|. It returns one on success and zero on error.
int CBS_get_last_u8(CBS* cbs, uint8_t* out);

// CBS_get_bytes sets |*out| to the next |len| bytes from |cbs| and advances
// |cbs|. It returns one on success and zero on error.
int CBS_get_bytes(CBS* cbs, CBS* out, size_t len);

// CBS_copy_bytes copies the next |len| bytes from |cbs| to |out| and advances
// |cbs|. It returns one on success and zero on error.
int CBS_copy_bytes(CBS* cbs, uint8_t* out, size_t len);

// CBS_get_u8_length_prefixed sets |*out| to the contents of an 8-bit,
// length-prefixed value from |cbs| and advances |cbs| over it. It returns one
// on success and zero on error.
int CBS_get_u8_length_prefixed(CBS* cbs, CBS* out);

// CBS_get_u16_length_prefixed sets |*out| to the contents of a 16-bit,
// big-endian, length-prefixed value from |cbs| and advances |cbs| over it. It
// returns one on success and zero on error.
int CBS_get_u16_length_prefixed(CBS* cbs, CBS* out);

// CBS_get_u24_length_prefixed sets |*out| to the contents of a 24-bit,
// big-endian, length-prefixed value from |cbs| and advances |cbs| over it. It
// returns one on success and zero on error.
int CBS_get_u24_length_prefixed(CBS* cbs, CBS* out);

// CBS_get_until_first finds the first instance of |c| in |cbs|. If found, it
// sets |*out| to the text before the match, advances |cbs| over it, and returns
// one. Otherwise, it returns zero and leaves |cbs| unmodified.
int CBS_get_until_first(CBS* cbs, CBS* out, uint8_t c);

// Parsing ASN.1
//
// |CBS| may be used to parse DER structures. Rather than using a schema
// compiler, the following functions act on tag-length-value elements in the
// serialization itself. Thus the caller is responsible for looping over a
// SEQUENCE, branching on CHOICEs or OPTIONAL fields, checking for trailing
// data, and handling explict vs. implicit tagging.
//
// Tags are represented as |unsigned| values in memory. The upper few bits store
// the class and constructed bit, and the remaining bits store the tag
// number. Note this differs from the DER serialization, to support tag numbers
// beyond 31. Consumers must use the constants defined below to decompose or
// assemble tags.
//
// This library treats an element's constructed bit as part of its tag. In DER,
// the constructed bit is computable from the type. The constants for universal
// types have the bit set. Callers must set it correctly for tagged types.
// Explicitly-tagged types are always constructed, and implicitly-tagged types
// inherit the underlying type's bit.

// CBS_ASN1_TAG_SHIFT is how much the in-memory representation shifts the class
// and constructed bits from the DER serialization.
#define CBS_ASN1_TAG_SHIFT 24

// CBS_ASN1_CONSTRUCTED may be ORed into a tag to set the constructed bit.
#define CBS_ASN1_CONSTRUCTED (0x20u << CBS_ASN1_TAG_SHIFT)

// The following values specify the tag class and may be ORed into a tag number
// to produce the final tag. If none is used, the tag will be UNIVERSAL.
#define CBS_ASN1_UNIVERSAL (0u << CBS_ASN1_TAG_SHIFT)
#define CBS_ASN1_APPLICATION (0x40u << CBS_ASN1_TAG_SHIFT)
#define CBS_ASN1_CONTEXT_SPECIFIC (0x80u << CBS_ASN1_TAG_SHIFT)
#define CBS_ASN1_PRIVATE (0xc0u << CBS_ASN1_TAG_SHIFT)

// CBS_ASN1_CLASS_MASK may be ANDed with a tag to query its class. This will
// give one of the four values above.
#define CBS_ASN1_CLASS_MASK (0xc0u << CBS_ASN1_TAG_SHIFT)

// CBS_ASN1_TAG_NUMBER_MASK may be ANDed with a tag to query its number.
#define CBS_ASN1_TAG_NUMBER_MASK ((1u << (5 + CBS_ASN1_TAG_SHIFT)) - 1)

// The following values are constants for UNIVERSAL tags. Note these constants
// include the constructed bit.
#define CBS_ASN1_BOOLEAN 0x1u
#define CBS_ASN1_INTEGER 0x2u
#define CBS_ASN1_BITSTRING 0x3u
#define CBS_ASN1_OCTETSTRING 0x4u
#define CBS_ASN1_NULL 0x5u
#define CBS_ASN1_OBJECT 0x6u
#define CBS_ASN1_ENUMERATED 0xau
#define CBS_ASN1_UTF8STRING 0xcu
#define CBS_ASN1_SEQUENCE (0x10u | CBS_ASN1_CONSTRUCTED)
#define CBS_ASN1_SET (0x11u | CBS_ASN1_CONSTRUCTED)
#define CBS_ASN1_NUMERICSTRING 0x12u
#define CBS_ASN1_PRINTABLESTRING 0x13u
#define CBS_ASN1_T61STRING 0x14u
#define CBS_ASN1_VIDEOTEXSTRING 0x15u
#define CBS_ASN1_IA5STRING 0x16u
#define CBS_ASN1_UTCTIME 0x17u
#define CBS_ASN1_GENERALIZEDTIME 0x18u
#define CBS_ASN1_GRAPHICSTRING 0x19u
#define CBS_ASN1_VISIBLESTRING 0x1au
#define CBS_ASN1_GENERALSTRING 0x1bu
#define CBS_ASN1_UNIVERSALSTRING 0x1cu
#define CBS_ASN1_BMPSTRING 0x1eu

// CBS_get_asn1 sets |*out| to the contents of DER-encoded, ASN.1 element (not
// including tag and length bytes) and advances |cbs| over it. The ASN.1
// element must match |tag_value|. It returns one on success and zero
// on error.
int CBS_get_asn1(CBS* cbs, CBS* out, unsigned tag_value);

// CBS_get_asn1_element acts like |CBS_get_asn1| but |out| will include the
// ASN.1 header bytes too.
int CBS_get_asn1_element(CBS* cbs, CBS* out, unsigned tag_value);

// CBS_peek_asn1_tag looks ahead at the next ASN.1 tag and returns one
// if the next ASN.1 element on |cbs| would have tag |tag_value|. If
// |cbs| is empty or the tag does not match, it returns zero. Note: if
// it returns one, CBS_get_asn1 may still fail if the rest of the
// element is malformed.
int CBS_peek_asn1_tag(const CBS* cbs, unsigned tag_value);

// CBS_get_any_asn1 sets |*out| to contain the next ASN.1 element from |*cbs|
// (not including tag and length bytes), sets |*out_tag| to the tag number, and
// advances |*cbs|. It returns one on success and zero on error. Either of |out|
// and |out_tag| may be NULL to ignore the value.
int CBS_get_any_asn1(CBS* cbs, CBS* out, unsigned* out_tag);

// CBS_get_any_asn1_element sets |*out| to contain the next ASN.1 element from
// |*cbs| (including header bytes) and advances |*cbs|. It sets |*out_tag| to
// the tag number and |*out_header_len| to the length of the ASN.1 header. Each
// of |out|, |out_tag|, and |out_header_len| may be NULL to ignore the value.
int CBS_get_any_asn1_element(CBS* cbs,
                             CBS* out,
                             unsigned* out_tag,
                             size_t* out_header_len);

// CBS_get_any_ber_asn1_element acts the same as |CBS_get_any_asn1_element| but
// also allows indefinite-length elements to be returned and does not enforce
// that lengths are minimal. It sets |*out_indefinite| to one if the length was
// indefinite and zero otherwise. If indefinite, |*out_header_len| and
// |CBS_len(out)| will be equal as only the header is returned (although this is
// also true for empty elements so |*out_indefinite| should be checked). If
// |out_ber_found| is not NULL then it is set to one if any case of invalid DER
// but valid BER is found, and to zero otherwise.
//
// This function will not successfully parse an end-of-contents (EOC) as an
// element. Callers parsing indefinite-length encoding must check for EOC
// separately.
int CBS_get_any_ber_asn1_element(CBS* cbs,
                                 CBS* out,
                                 unsigned* out_tag,
                                 size_t* out_header_len,
                                 int* out_ber_found,
                                 int* out_indefinite);

// CBS_get_asn1_uint64 gets an ASN.1 INTEGER from |cbs| using |CBS_get_asn1|
// and sets |*out| to its value. It returns one on success and zero on error,
// where error includes the integer being negative, or too large to represent
// in 64 bits.
int CBS_get_asn1_uint64(CBS* cbs, uint64_t* out);

// CBS_get_asn1_int64 gets an ASN.1 INTEGER from |cbs| using |CBS_get_asn1|
// and sets |*out| to its value. It returns one on success and zero on error,
// where error includes the integer being too large to represent in 64 bits.
int CBS_get_asn1_int64(CBS* cbs, int64_t* out);

// CBS_get_asn1_bool gets an ASN.1 BOOLEAN from |cbs| and sets |*out| to zero
// or one based on its value. It returns one on success or zero on error.
int CBS_get_asn1_bool(CBS* cbs, int* out);

// CBS_get_optional_asn1 gets an optional explicitly-tagged element from |cbs|
// tagged with |tag| and sets |*out| to its contents, or ignores it if |out| is
// NULL. If present and if |out_present| is not NULL, it sets |*out_present| to
// one, otherwise zero. It returns one on success, whether or not the element
// was present, and zero on decode failure.
int CBS_get_optional_asn1(CBS* cbs, CBS* out, int* out_present, unsigned tag);

// CBS_get_optional_asn1_octet_string gets an optional
// explicitly-tagged OCTET STRING from |cbs|. If present, it sets
// |*out| to the string and |*out_present| to one. Otherwise, it sets
// |*out| to empty and |*out_present| to zero. |out_present| may be
// NULL. It returns one on success, whether or not the element was
// present, and zero on decode failure.
int CBS_get_optional_asn1_octet_string(CBS* cbs,
                                       CBS* out,
                                       int* out_present,
                                       unsigned tag);

// CBS_get_optional_asn1_uint64 gets an optional explicitly-tagged
// INTEGER from |cbs|. If present, it sets |*out| to the
// value. Otherwise, it sets |*out| to |default_value|. It returns one
// on success, whether or not the element was present, and zero on
// decode failure.
int CBS_get_optional_asn1_uint64(CBS* cbs,
                                 uint64_t* out,
                                 unsigned tag,
                                 uint64_t default_value);

// CBS_get_optional_asn1_bool gets an optional, explicitly-tagged BOOLEAN from
// |cbs|. If present, it sets |*out| to either zero or one, based on the
// boolean. Otherwise, it sets |*out| to |default_value|. It returns one on
// success, whether or not the element was present, and zero on decode
// failure.
int CBS_get_optional_asn1_bool(CBS* cbs,
                               int* out,
                               unsigned tag,
                               int default_value);

// CBS_is_valid_asn1_bitstring returns one if |cbs| is a valid ASN.1 BIT STRING
// body and zero otherwise.
int CBS_is_valid_asn1_bitstring(const CBS* cbs);

// CBS_asn1_bitstring_has_bit returns one if |cbs| is a valid ASN.1 BIT STRING
// body and the specified bit is present and set. Otherwise, it returns zero.
// |bit| is indexed starting from zero.
int CBS_asn1_bitstring_has_bit(const CBS* cbs, unsigned bit);

// CBS_is_valid_asn1_integer returns one if |cbs| is a valid ASN.1 INTEGER,
// body and zero otherwise. On success, if |out_is_negative| is non-NULL,
// |*out_is_negative| will be set to one if |cbs| is negative and zero
// otherwise.
int CBS_is_valid_asn1_integer(const CBS* cbs, int* out_is_negative);

// CBS_is_unsigned_asn1_integer returns one if |cbs| is a valid non-negative
// ASN.1 INTEGER body and zero otherwise.
int CBS_is_unsigned_asn1_integer(const CBS* cbs);

}  // namespace certificate_transparency
