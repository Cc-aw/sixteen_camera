OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Firmware starts at 0x82000000. Live video DMA pools occupy the coherent
 * CPU aliases 0x88000000..0x88ffffff; the stack is above those pools. */
MEMORY { DDR (rwx) : ORIGIN = 0x82000000, LENGTH = 128M }
PHDRS {
    text PT_LOAD FLAGS(5);
    data PT_LOAD FLAGS(6);
}
SECTIONS {
    .text.init : { KEEP(*(.text.init)) } > DDR :text
    .text ALIGN(4096) : { *(.text .text.*) } > DDR :text
    .rodata : { *(.rodata .rodata.*) } > DDR :text
    .data ALIGN(4096) : { *(.data .data.*) } > DDR :data
    .sdata : {
        __global_pointer$ = . + 0x800;
        *(.srodata .srodata.* .sdata .sdata.*)
    } > DDR :data
    .bss ALIGN(64) (NOLOAD) : {
        __bss_start = .;
        *(.sbss .sbss.* .scommon .bss .bss.* COMMON)
        . = ALIGN(8);
        __bss_end = .;
    } > DDR :data
    . = ALIGN(4096);
    _end = .;
    __stack_bottom = ORIGIN(DDR) + LENGTH(DDR) - 1M;
    __stack_top = ORIGIN(DDR) + LENGTH(DDR);
    ASSERT(_end < __stack_bottom, "YOLO32 model overlaps stack")
    ASSERT(_end <= 0x88000000, "YOLO32 image overlaps live video DMA pools")
}
