#include <stddef.h>
int abs(int v){return v<0?-v:v;}
size_t strlen(const char *s){size_t n=0;while(s[n])n++;return n;}
