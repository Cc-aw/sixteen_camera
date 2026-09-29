OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    DDR (rwx) : ORIGIN = 0x80000000, LENGTH = 1M
}

PHDRS
{
    code PT_LOAD FLAGS(5);
    data PT_LOAD FLAGS(6);
}

__stack_size = 32K;

SECTIONS
{
    . = ORIGIN(DDR);

    .text.init : ALIGN(16)
    {
        KEEP(*(.text.init))
    } > DDR :code

    .text : ALIGN(16)
    {
        *(.text .text.*)
    } > DDR :code

    .rodata : ALIGN(16)
    {
        *(.rodata .rodata.*)
    } > DDR :code

    .data : ALIGN(16)
    {
        __data_start = .;
        PROVIDE(__global_pointer$ = . + 0x800);
        *(.data .data.*)
        *(.sdata .sdata.*)
        __data_end = .;
    } > DDR :data

    .bss (NOLOAD) : ALIGN(16)
    {
        __bss_start = .;
        *(.sbss .sbss.*)
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end = .;
    } > DDR :data

    . = ALIGN(16);
    __image_end = .;
    __stack_bottom = ORIGIN(DDR) + LENGTH(DDR) - __stack_size;
    __stack_top = ORIGIN(DDR) + LENGTH(DDR);

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame .eh_frame.*)
        *(.riscv.attributes)
    }
}

ASSERT(__image_end <= __stack_bottom, "firmware image overlaps the stack")
