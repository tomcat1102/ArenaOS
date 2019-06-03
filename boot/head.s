;   head.s -- head of the kernel. 6.3

%include "boot.inc"

[bits 32]
global startup_32

startup_32:
    ; TODO!!!! MUST CHANGE DS DESCRIPTOR LATER
    mov ax, SYS_SEG
    mov es, ax
    mov bp, MSG_HEAD
    mov cx, 21
    call print 

    jmp $

%include "print.asm"

MSG_HEAD:
    db "Enter kernel head: "
    db 0xa, 0xd

times 512 - ($ - $$) db 0xA
