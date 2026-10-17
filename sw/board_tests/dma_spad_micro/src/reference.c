#include "micro.h"

static int scaled(uint8_t byte,uint16_t bits)
{
    unsigned exponent=(bits>>10)&31, mantissa=bits&1023;
    float scale=(float)(exponent?1024+mantissa:mantissa);
    int shift=exponent?(int)exponent-25:-24;
    while(shift>0){scale*=2;shift--;}
    while(shift<0){scale/=2;shift++;}
    if(bits&0x8000)scale=-scale;
    float value=(float)(byte>=128?(int)byte-256:(int)byte)*scale;
    if(value>=127)return 127;
    if(value<=-128)return -128;
    int result=(int)value;
    float fraction=value-(float)result;
    if(fraction>0.5f||(fraction==0.5f&&(result&1)))result++;
    if(fraction< -0.5f||(fraction== -0.5f&&(result&1)))result--;
    return result;
}

void micro_fill_source(uint8_t *source,const MicroCase *c)
{
    for(unsigned i=0;i<micro_source_bytes(c);i++)source[i]=0xd7;
    for(unsigned row=0;row<c->rows;row++)
        for(unsigned col=0;col<c->cols;col++)
            source[c->offset+row*c->stride+col]=(uint8_t)(row*37+col*11+17);
}

void micro_reference(const uint8_t *source,uint8_t *gold,const MicroCase *c)
{
    for(unsigned i=0;i<micro_output_bytes(c);i++)gold[i]=MICRO_POISON;
    /* Original per-source, reverse-repeat masked writes. No sliding-window
     * algorithm is used to compute the expected destination. */
    unsigned first=MICRO_DEST-c->pixels;
    for(unsigned row=0;row<c->rows;row++)
        for(unsigned repeat=c->pixels;repeat-- >0;)
            for(unsigned col=0;col<c->cols;col++) {
                unsigned dest=MICRO_DEST+row-repeat;
                gold[(dest-first)*MICRO_DIM+repeat*c->cols+col]=
                    (uint8_t)scaled(source[c->offset+row*c->stride+col],c->scale);
            }
}

static void reads(unsigned address,unsigned bytes,MicroTraffic *t)
{
    while(bytes) {
        unsigned a=32-address%32,b=64-address%64;
        if(a>bytes)a=bytes;
        if(b>bytes)b=bytes;
        unsigned take=b>a?b:a;
        if(b>a){t->get64++;t->returned+=64;}
        else {t->get32++;t->returned+=32;}
        bytes-=take;address+=take;
    }
}

MicroTraffic micro_predict(const MicroCase *c,unsigned mode)
{
    MicroTraffic t={0};
    unsigned continuous=c->stride==c->cols;
    unsigned group=mode!=0&&((continuous&&c->rows>1)||(mode==2&&c->pixels>1));
    t.merge=group&&continuous&&c->rows>1;
    t.assembly=group&&mode==2;
    if(t.merge)reads(c->offset,c->rows*c->cols,&t);
    else for(unsigned row=0;row<c->rows;row++)
        reads(c->offset+row*c->stride,c->cols,&t);
    unsigned fragments=t.get32+t.get64;
    t.writes=t.assembly?c->rows+c->pixels-1:
        (group?c->rows:fragments)*c->pixels;
    t.assembled=t.assembly?t.writes:0;
    t.groups=group;
    t.rows=c->rows;t.bytes=c->rows*c->cols;
    t.get32*=c->ops;t.get64*=c->ops;t.returned*=c->ops;
    t.writes*=c->ops;t.assembled*=c->ops;t.groups*=c->ops;
    t.rows*=c->ops;t.bytes*=c->ops;
    return t;
}
