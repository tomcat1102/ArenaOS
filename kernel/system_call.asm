; System_call.asm 6.12
;
; Contains system-call low-level handling routines. Also contains some interrupt
; handlers cause I don't wanna create more asm files. It's good to put them here
[bits 32]
global timer_interrupt
extern jiffies

timer_interrupt:
    nop 
    nop 
    inc dword [jiffies]
    mov eax, 0xDEADFADE

    mov al, 0x20
    out 0x20, al       ; Send EOI to 8259

    iret