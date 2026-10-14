/* Board sanity check, separate from inference and its serial reference.
 * Scalar max/nearest lookup is only an element oracle for this command. */
static elem_t memory_test_src[30*40*128] __attribute__((aligned(64)));
static elem_t memory_test_dst[60*80*128+64] __attribute__((aligned(64)));
static void memory_test_field(const char *name,uint64_t n) {
    console_puts(" "); console_puts(name); console_putc('='); console_put_hex64(n);
}
void yolo32_memory_test(void) {
    if (yolo32_independent_enabled) yolo32_fail("memory_test_active");
    yolo32_set_analysis(0);
    console_puts("YOLO32_MEMORY_TEST_BEGIN workers=3 cases_per_worker=7\r\n");
    static const unsigned cases[7][5]={
        {0,1,1,128,0}, {0,3,4,65,1}, {0,15,20,128,1}, {0,15,20,128,2},
        {1,3,17,65,2}, {1,15,20,128,2}, {1,30,40,64,2}
    };
    uint64_t errors=0;
    for (unsigned w=0;w<3;++w) {
        yolo32_independent_select(w);
        for (unsigned i=0;i<7;++i) {
            unsigned resize=cases[i][0],h=cases[i][1],width=cases[i][2],c=cases[i][3],pattern=cases[i][4];
            size_t input=(size_t)h*width*c,output=input*(resize ? 4 : 1);
            for (size_t n=0;n<input;++n)
                memory_test_src[n]=pattern==0 ? -128 : pattern==1 ?
                    -128+(int)((n*17+n/c+w*23)%127) : (int)((n*37+n/c*13+w*29)%256)-128;
            memset(memory_test_dst,85,output+64);
            uint64_t start=read_cycle();
            if (resize) yolo32_memory_resize2(memory_test_src,memory_test_dst,h,width,c);
            else yolo32_memory_pool5(memory_test_src,memory_test_dst,h,width,c);
            uint64_t cycles=read_cycle()-start,mismatches=0,first=UINT64_MAX;
            unsigned oh=h*(resize ? 2 : 1),ow=width*(resize ? 2 : 1);
            for (unsigned y=0;y<oh;++y) for (unsigned x=0;x<ow;++x) for (unsigned ch=0;ch<c;++ch) {
                int expected=-128;
                if (resize) expected=memory_test_src[((size_t)(y/2)*width+x/2)*c+ch];
                else for (int ky=-2;ky<=2;++ky) for (int kx=-2;kx<=2;++kx) {
                    int iy=(int)y+ky,ix=(int)x+kx;
                    if (iy>=0 && iy<(int)h && ix>=0 && ix<(int)width) {
                        int v=memory_test_src[((size_t)iy*width+ix)*c+ch];
                        if (v>expected) expected=v;
                    }
                }
                size_t n=((size_t)y*ow+x)*c+ch;
                if (memory_test_dst[n]!=expected) { if (!mismatches) first=n; ++mismatches; }
            }
            unsigned guards=0;
            for (unsigned n=0;n<64;++n) guards+=memory_test_dst[output+n]!=85;
            console_puts("YOLO32_MEMORY_TEST_CASE"); memory_test_field("worker",w); memory_test_field("case",i);
            console_puts(resize ? " kind=resize" : " kind=pool");
            memory_test_field("h",h); memory_test_field("w",width); memory_test_field("c",c);
            memory_test_field("pattern",pattern); memory_test_field("elements",output);
            memory_test_field("mismatches",mismatches); memory_test_field("guard_errors",guards);
            memory_test_field("first",first); memory_test_field("cycles",cycles); console_puts("\r\n");
            errors+=mismatches+guards;
        }
    }
    console_puts(errors ? "YOLO32_MEMORY_TEST_RESULT FAIL" : "YOLO32_MEMORY_TEST_RESULT PASS");
    memory_test_field("errors",errors); console_puts("\r\n");
    if (errors) yolo32_fail("memory_test_mismatch");
}
