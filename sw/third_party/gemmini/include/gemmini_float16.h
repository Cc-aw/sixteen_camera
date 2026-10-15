#ifndef GEMMINI_FLOAT16_H
#define GEMMINI_FLOAT16_H
#include <stdint.h>

/* The software API takes numerical float scales; the command carries IEEE
 * binary16. Round to nearest, ties to even, without requiring Zfh or libgcc
 * half-precision helpers on the Rocket core. */
static inline uint16_t gemmini_float_to_half(float value) {
    union { float f; uint32_t u; } v = { .f = value };
    uint16_t sign = (uint16_t)((v.u >> 16) & 0x8000);
    uint32_t mant = v.u & 0x7fffff;
    int exp = (int)((v.u >> 23) & 255);
    if (exp == 255)
        return sign | 0x7c00 | (mant ? ((mant >> 13) | 0x200) : 0);
    exp -= 112;
    if (exp >= 31) return sign | 0x7c00;
    unsigned shift = 13;
    if (exp <= 0) {
        if (exp < -10) return sign;
        mant |= 0x800000;
        shift = (unsigned)(14 - exp);
        exp = 0;
    }
    uint32_t result = ((uint32_t)exp << 10) + (mant >> shift);
    uint32_t remainder = mant & ((1u << shift) - 1);
    uint32_t midpoint = 1u << (shift - 1);
    result += remainder > midpoint || (remainder == midpoint && (result & 1));
    return sign | (uint16_t)result;
}

static inline float gemmini_half_to_float(uint16_t value) {
    uint32_t sign = (uint32_t)(value & 0x8000) << 16;
    uint32_t mant = value & 1023;
    unsigned exp = (value >> 10) & 31;
    uint32_t bits;
    if (exp == 0) {
        if (mant == 0) bits = sign;
        else {
            int e = -14;
            while (!(mant & 1024)) { mant <<= 1; --e; }
            bits = sign | ((uint32_t)(e + 127) << 23) | ((mant & 1023) << 13);
        }
    } else if (exp == 31) bits = sign | 0x7f800000 | (mant << 13);
    else bits = sign | ((exp + 112) << 23) | (mant << 13);
    union { uint32_t u; float f; } v = { .u = bits };
    return v.f;
}
#endif
