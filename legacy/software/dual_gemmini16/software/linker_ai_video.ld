OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Shared bare-metal layout for the video + AI image.  Video framebuffer
 * pools are allocated by hardware below 0x82000000; the model image uses the
 * following DDR region and keeps its stack at the top of the image. */
MEMORY {
  DDR (rwx) : ORIGIN = 0x80000000, LENGTH = 512M
}

SECTIONS {
  . = ORIGIN(DDR);
  .text.init : { KEEP(*(.text.init)) } > DDR
  . = ALIGN(0x1000);
  .tohost : { *(.tohost) } > DDR
  . = ALIGN(0x1000);
  .text : { *(.text .text.*) } > DDR
  .rodata : { *(.rodata .rodata.*) } > DDR
  .data : { *(.data .data.*) } > DDR
  .sdata : {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16 .srodata.cst8 .srodata.cst4 .srodata.cst2)
    *(.srodata .srodata.* .sdata .sdata.* .gnu.linkonce.s.*)
  } > DDR
  . = ALIGN(64);
  __bss_start = .;
  .sbss : { *(.sbss .sbss.* .scommon) } > DDR
  .bss : { *(.bss .bss.* COMMON) } > DDR
  __bss_end = .;
  .tdata : { _tdata_begin = .; *(.tdata .tdata.*); _tdata_end = .; } > DDR
  .tbss : { *(.tbss .tbss.*); _tbss_end = .; } > DDR
  . = ALIGN(4096);
  _end = .;
  __stack_bottom = ORIGIN(DDR) + LENGTH(DDR) - 16M;
  __stack_top = ORIGIN(DDR) + LENGTH(DDR);
}
