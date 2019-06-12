; expections.asm 6.11
; Contains exception handlers for CPU exceptions, e.g divide error.
[bits 32]
global divide_error

divide_error:
    nop
    mov ecx, 0x3   ; changing the divisor to non-zero should avoid the error
    iret
