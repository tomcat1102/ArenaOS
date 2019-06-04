;   head.s -- head of the kernel. 6.3

%include "boot.inc"

[bits 32]
global startup_32

startup_32:
    mov ax, 0x10       ; load data segment selector to each segment registers
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Cannot print anymore! How to better debug with print() ?

    jmp $

MSG_HEAD:
    db "Enter kernel head: "
    db 0xa, 0xd

times 1024 - ($ - $$) db 0xAA
times 1024 db 0xBB
times 1024 db 0xCC
times 1024 db 0xDD

kernel_gdt:
    dq 0x0000000000000000
    dq 0x00c09a0000000fff
    dq 0x00c0920000000fff
    dq 0x0000000000000000
    times 252 dq 0
kernel_idt:
    times 256 dq 0    

