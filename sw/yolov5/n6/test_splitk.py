#!/usr/bin/env python3
"""I: adapted C helpers. P: execute helpers against an independent scalar matmul model.
O: tail/partition/accumulation checks. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'build/yolov5nu_n6_v4'
s=(OUT/'025/main.c').read_text()
a=s.index('static void gemmini_splitk_1x1_two_slice_i8(')
b=s.index('\nstatic ',s.index('static void gemmini_splitk_1x1_multi_slice_i8(')+15)
helpers=s[a:b]
r=(ROOT/'sw/yolov5/n6/n6_runtime.h').read_text()
a=r.index('static size_t n6_tile_i(');b=r.index('extern const int8_t',a)
capacity=r[a:b]
pre=r'''
/* I: generated helpers. P: scalar WS instruction model. O: compared arrays.
 * A: 王志瑞. T: 2026-09-10. */
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>
#include <math.h>
typedef int8_t elem_t; typedef int32_t acc_t;
#define DIM 64
#define ACC_ROWS 2048
#define BANK_NUM 8
#define BANK_ROWS 1024
#define MVIN_SCALE_IDENTITY 1
#define WS 1
#define SILU_LUT 6
#define gemmini_fence() ((void)0)
#define gemmini_extended_config_ex(...) ((void)0)
#define gemmini_extended3_config_ld(...) ((void)0)
static float store_scale;
static const elem_t *lut;
#define gemmini_extended_config_st(stride,act,scale) (store_scale=(scale))
#define gemmini_config_silu_lut(t) (lut=(t))
#define n6_wait() ((void)0)
#define n6_begin(...) ((void)0)
#define n6_end() ((void)0)
#define n6_flush(p,n) ((void)0)
static int32_t acc[65536];
static int8_t apart[2][262144];
static size_t ar[2],ak[2];
static size_t calls;
static void sp_tiled_matmul_ws(const elem_t*A,const elem_t*B,const void*D,void*C,
 float as,float bs,int ds,size_t I,size_t J,size_t K,size_t pi,size_t pj,size_t pk,
 size_t astride,size_t bstride,size_t dstride,size_t cstride,
 bool at,bool bt,bool full,bool low,bool nobias,bool repeat,int act,int aid,int bid) {
 assert(!at&&!bt&&!full&&!low&&(!D||repeat)&&bid==0&&as==1&&bs==1&&ds==1);
 size_t rows=I*64-pi,cols=J*64-pj,ks=K*64-pk;
 assert(pi<64&&pj<64&&pk<64&&cols==bstride&&cols==cstride&&ks==astride);
 assert(I*J*64<=ACC_ROWS/2&&I*K*64+K*J*64<=BANK_NUM*BANK_ROWS/2);
 assert(rows*cols<=65536);
 int part=aid?aid-1:0;assert(part>=0&&part<2);
 if(A){ar[part]=rows;ak[part]=ks;for(size_t i=0;i<rows;i++)memcpy(apart[part]+i*ks,A+i*astride,ks);}
 else {assert(aid&&ar[part]==rows&&ak[part]==ks);}
 for(size_t i=0;i<rows;i++)for(size_t j=0;j<cols;j++) {
   size_t x=i*cols+j;
   if(D&&!nobias) acc[x]=((const acc_t*)D)[j];
   for(size_t k=0;k<ks;k++)acc[x]+=(int)apart[part][i*ks+k]*(int)B[k*bstride+j];
   if(C){int q=(int)nearbyintf(acc[x]*store_scale);if(q>127)q=127;if(q< -128)q=-128;((elem_t*)C)[i*cstride+j]=act==SILU_LUT?lut[(uint8_t)q]:q;}
 }
 calls++;
}
'''
post=r'''
static elem_t table0[256], table1[256];
static void run_case(int rows,int k,int j,int kind) {
 int slices=kind==2?4:2, size=rows*j;
 elem_t *a[4],*w=malloc(slices*k*j),*w1=malloc(slices*k*j);
 elem_t *o=malloc(size+64),*o1=malloc(size+64);acc_t *bias=malloc(j*sizeof(acc_t));
 for(int t=0;t<4;t++){a[t]=malloc(rows*k);for(int x=0;x<rows*k;x++)a[t][x]=(x+3*t)%5-2;}
 for(int x=0;x<slices*k*j;x++){w[x]=(x*3)%5-2;w1[x]=(x*7+1)%5-2;}
 for(int x=0;x<j;x++)bias[x]=x%7-3;
 memset(o,0x55,size+64);memset(o1,0x55,size+64);lut=table0;store_scale=1;
 if(kind==0)gemmini_splitk_1x1_two_slice_i8(a[0],a[1],w,bias,o,rows,k,j,1,1,1,SILU_LUT,1);
 if(kind==1)gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(a[0],a[1],w,bias,o,table0,j,1,w1,bias,o1,table1,j,1,rows,k,1,1,1,SILU_LUT);
 if(kind==2){const elem_t*in[]={a[0],a[1],a[2],a[3]};int ch[]={k,k,k,k};float sc[]={1,1,1,1};gemmini_splitk_1x1_multi_slice_i8(in,ch,sc,4,w,bias,o,rows,j,1,SILU_LUT,1);}
 for(int consumer=0;consumer<(kind==1?2:1);consumer++){
 elem_t*weights=consumer?w1:w,*out=consumer?o1:o,*table=consumer?table1:table0;
 for(int i=0;i<rows;i++)for(int c=0;c<j;c++){
   int sum=bias[c];for(int t=0;t<slices;t++)for(int x=0;x<k;x++)sum+=a[t][i*k+x]*weights[(t*k+x)*j+c];
   if(sum>127)sum=127;if(sum< -128)sum=-128;
   assert(out[i*j+c]==table[(uint8_t)sum]);
 }
 for(int x=size;x<size+64;x++)assert((uint8_t)out[x]==0x55);
 }
 for(int t=0;t<4;t++)free(a[t]);free(w);free(w1);free(o);free(o1);free(bias);
}
int main(void){
 for(int x=0;x<256;x++){table0[x]=(int8_t)x;table1[x]=(int8_t)x/2;}
 int count=0;
 int sizes[]={41,65,300,1100};
 for(int kind=0;kind<3;kind++)for(int r=0;r<4;r++)for(int k=16;k<=128;k*=2)for(int j=32;j<=256;j*=2){run_case(sizes[r],k,j,kind);count++;}
 printf("PASS split-K scalar comparison: cases=%d instruction_calls=%zu; J32 tail, K16/32 tails, I tails, tile transitions, dual-LUT SPAD reuse, output guards\n",count,calls);
 return 0;
}
'''
p=OUT/'test_splitk_host.c';p.write_text(pre+capacity+helpers+post)
subprocess.run(['gcc','-O2',str(p),'-lm','-o',str(OUT/'test_splitk_host')],check=True)
result=subprocess.run([str(OUT/'test_splitk_host')],check=True,capture_output=True,text=True)
print(result.stdout,end='');(OUT/'test_splitk.log').write_text(result.stdout)
