#include <stdio.h>
#include <stdlib.h>
#include "micro.h"

int main(int argc,char **argv)
{
    if(argc!=9)return 2;
    MicroCase c={(unsigned)strtoul(argv[1],0,0),(unsigned)strtoul(argv[2],0,0),
        (unsigned)strtoul(argv[3],0,0),(unsigned)strtoul(argv[4],0,0),
        (unsigned)strtoul(argv[5],0,0),(unsigned)strtoul(argv[6],0,0),
        (uint16_t)strtoul(argv[7],0,0)};
    unsigned mode=(unsigned)strtoul(argv[8],0,0);
    uint8_t *source=malloc(micro_source_bytes(&c)),*gold=malloc(micro_output_bytes(&c));
    if(!source||!gold)return 3;
    micro_fill_source(source,&c);micro_reference(source,gold,&c);
    MicroTraffic t=micro_predict(&c,mode);
    printf("%u %u %u %u %u %u %u %u %u %u\n",t.get32,t.get64,t.returned,t.writes,t.groups,
        t.assembled,t.rows,t.bytes,t.merge,t.assembly);
    printf("%llu %llu\n",(unsigned long long)micro_load_config(c.scale,c.pixels),
        (unsigned long long)micro_shape(c.rows,c.cols,MICRO_DEST));
    for(unsigned i=0;i<micro_output_bytes(&c);i++)printf("%02x",gold[i]);
    puts("");free(source);free(gold);return 0;
}
