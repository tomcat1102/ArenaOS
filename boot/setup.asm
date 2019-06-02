; Setup sector. 5.2

%include "boot.inc"

[bits 16]
global _setup

_setup:
    ; Save various information for later use

    ; save cursor position


    mov ax, cs
    mov ds, ax
    mov es, ax

    mov bp, MSG_SETUP_OK
    mov cx, 28
    call print

    jmp $

%include "print.asm"

MSG_SETUP_OK:
    db "Enter setup: damn all good"
    db 0xa, 0xd

times 512 - ($ - $$) db 0 ; fill this sector with 0

