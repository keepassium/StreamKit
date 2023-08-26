//
// The MIT License (MIT)
//
// Copyright (c) 2023 Ihar Katkavets

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

/**
 * Salsa 20 implementation adopted from the reference
 * implementation by D. J. Bernstein https://cr.yp.to/salsa20.html
 * Taken from https://cr.yp.to/snuffle/salsa20/merged/ecrypt-sync.h
 * Public domain.
 */

#ifndef salsa20_h
#define salsa20_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef uint8_t u8;
typedef uint32_t u32;

typedef struct
{
  u32 input[16]; /* could be compressed */
} SALSA20_ctx;

void SALSA20_init();

void SALSA20_keysetup(
  SALSA20_ctx* ctx,
  const u8* key,
  u32 keysize,                /* Key size in bits. */
  u32 ivsize);                /* IV size in bits. */

void SALSA20_ivsetup(
  SALSA20_ctx* ctx,
  const u8* iv);

void SALSA20_encrypt_bytes(
  SALSA20_ctx* ctx,
  const u8* plaintext,
  u8* ciphertext,
  u32 msglen);                /* Message length in bytes. */

void SALSA20_decrypt_bytes(
  SALSA20_ctx* ctx,
  const u8* ciphertext,
  u8* plaintext,
  u32 msglen);                /* Message length in bytes. */

#define SALSA20_BLOCKLENGTH 64                  /* [edit] */

void SALSA20_encrypt_blocks(
  SALSA20_ctx* ctx,
  const u8* plaintext,
  u8* ciphertext,
  u32 blocks);                /* Message length in blocks. */

void SALSA20_decrypt_blocks(
  SALSA20_ctx* ctx,
  const u8* ciphertext,
  u8* plaintext,
  u32 blocks);                /* Message length in blocks. */

#ifdef __cplusplus
}
#endif

#endif /* salsa20_h */
