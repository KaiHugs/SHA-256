/*
  Startup code for PicoRV32
 */

.section .text._start
.global _start

_start:
    lui sp, %hi(_stack_top)
    addi sp, sp, %lo(_stack_top)
    
    j main

loop:
    j loop