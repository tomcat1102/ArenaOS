;   head.s -- head of the kernel. 6.3

%include "../boot/boot.inc"

[bits 32]
global startup_32
extern stack_start
extern main

startup_32:
    mov ax, 0x10       ; load data segment selector to each segment registers
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ; TODO have to set temp stack to debug main(), which uses stack of course.
    mov ss, ax
    mov esp, 0x90000    ; stack top at INIT_SEG 0x9000, note the zero at end

    ; Note 
    mov eax, 0x2000
    call eax       ; TODO try call later, main address should be saved 
    nop
    nop 

    jmp $


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

