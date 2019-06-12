; interrupts.asm 6.12
; Contains interrupt handlers for interrupts, e.g keyboard interrupt.
[bits 32]
global keyboard_interrupt

keyboard_interrupt:
    nop

    in al, 0x60         ; read scan code
    nop
    nop
    in al, 0x61         ; get PPI port status
    nop
    nop
    or al, 0x80         ; set bit7 to disable keyboard
    nop
    nop
    out 0x61, al        ; send status
    nop
    nop
    and al, 0x7f        ; reset bit7 to enable keyboard
    out 0x61, al        ; send status

    mov al, 0x20
    out 0x20, al        ; send EOI signal to 8259
    iret
