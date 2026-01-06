/*
 * Linker script for PicoRV32 Bitcoin Miner
 * 
 * Memory Map:
 * 0x00000000 - 0x00003FFF : RAM (16KB)
 * 0x80000000 - 0x800000FF : Miner MMIO
 */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
    .text : {
        *(.text._start)
        *(.text*)
    } > RAM

    .rodata : {
        *(.rodata*)
    } > RAM

    .data : {
        *(.data*)
    } > RAM

    .bss : {
        *(.bss*)
        *(COMMON)
    } > RAM

    /* Stack grows downward from end of RAM */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}

ENTRY(_start)