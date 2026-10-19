#include "suite.h"
const TestShape shapes[3] = {{12,32,2,12,31}, {12,32,2,64,7}, {32,32,1,32,0}};

uint64_t pattern_word(unsigned lane, size_t offset, unsigned pass)
{
    uint64_t x = (offset / 8) ^ (UINT64_C(0x9e3779b97f4a7c15) * (lane+1));
    x ^= x >> 30; x *= UINT64_C(0xbf58476d1ce4e5b9);
    x ^= x >> 27; x *= UINT64_C(0x94d049bb133111eb); x ^= x >> 31;
    return pass ? ~x : x;
}
uint8_t source_byte(unsigned lane, unsigned row, unsigned col)
{
    return (uint8_t)(17 + lane*61 + row*37 + col*11);
}
size_t source_size(const TestShape *s) { return s->offset+(s->rows-1)*s->stride+s->cols; }
size_t output_size(const TestShape *s) { return (s->rows+s->pixels+1)*DIM; }
void fill_source(uint8_t *p, const TestShape *s, unsigned lane)
{
    for (size_t i=0;i<source_size(s);i++) p[i]=0xd7;
    for (unsigned r=0;r<s->rows;r++) for (unsigned c=0;c<s->cols;c++)
        p[s->offset+r*s->stride+c]=source_byte(lane,r,c);
}
void reference_output(uint8_t *p, const TestShape *s, unsigned lane)
{
    for (size_t i=0;i<output_size(s);i++) p[i]=0xa5;
    /* Independent original Gemmini reverse-repeat writes, unit FP16 scale. */
    for (unsigned r=0;r<s->rows;r++) for (unsigned k=s->pixels;k-- >0;)
        for (unsigned c=0;c<s->cols;c++)
            p[(s->pixels+r-k)*DIM+k*s->cols+c]=source_byte(lane,r,c);
}
