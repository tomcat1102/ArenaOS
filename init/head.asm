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
    lss esp, [stack_start]  ; set protected mode stack before calling routine

    call setup_idt
    call setup_gdt      ; set protected mode gdt & idt

    mov eax, 0x10       ; update seg registers cause data seg is 16MB not 8MB
    mov ds, ax          ; though they are also 0x01 before setting gdt, the 
    mov es, ax          ; correponding cached 'shadow registers' is not updated
    mov fs, ax          ; 
    mov gs, ax          ; The shadow update can be seen in qemu console
    lss esp, [stack_start]

    jmp 8:cs_go         ; Don't forget to update cs
cs_go:

    xor eax, eax        ; test whether A20 is open
A20:                    ; In read mode, A20 isn't activated and we can address
    inc eax             ; only first 1M physical memory.
    mov [0x100000], eax ;
    cmp eax, [0x100000] ; In protected mode, A20 should be open and we can thus
    je A20              ; address up to 4GB linear space. (16MB physical mem)
                        ;
                        ; Loop forver If failed, can't print any error msg

    mov eax, main       ; near call in same code seg, absolute indirect via eax
    call eax            ; main is far away from start_32, can't just call main. 
    
    jmp $

setup_gdt:
    lgdt [gdt_descr]
    ret
setup_idt:              ; TODO setup dummy interrupt handler before sti()
    lidt [idt_descr]    ; specific handlers will be installed later 
    ret

; *************************ABOVE OVERWRITTEN !!! ***************************
;   code and data in 0x0000 ~ 0x1000 will later be overwritten as page table 
times 1024 - ($ - $$) db 0xAA
times 1024 db 0xBB
times 1024 db 0xCC
times 1024 db 0xDD

kernel_gdt:
    dq 0x0000000000000000       ; null descriptor
    dq 0x00c09a0000000fff       ; 16 MB code segment
    dq 0x00c0920000000fff       ; 16 MB data segment
    dq 0x0000000000000000       ; don't use
    times 252 dq 0
kernel_idt:
    times 256 dq 0    

gdt_descr:
    dw 256 * 8 - 1
    dd kernel_gdt
idt_descr:
    dw 256 * 8 - 1
    dd kernel_idt

; Always check that main() is located at 0x200C
