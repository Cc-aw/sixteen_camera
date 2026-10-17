OUTPUT_ARCH(riscv)
ENTRY(_start)
MEMORY { DDR (rwx) : ORIGIN = 0x82000000, LENGTH = 512K }
SECTIONS {
 .text : { KEEP(*(.text.init)) *(.text .text.*) } > DDR
 .rodata : { *(.rodata .rodata.*) } > DDR
 .data : ALIGN(64) { __global_pointer$ = . + 0x800; *(.sdata .sdata.* .data .data.*) } > DDR
 .bss (NOLOAD) : ALIGN(64) { __bss_start = .; *(.sbss .sbss.* .bss .bss.* COMMON) . = ALIGN(64); __bss_end = .; } > DDR
 .stack (NOLOAD) : ALIGN(64) { . += 0x4000; __stack_top = .; } > DDR
 _end = .;
}
