;   head.s -- head of the kernel. 6.3

%include "../boot/boot.inc"

[bits 32]
global startup_32
extern stack_start
extern main
extern printk

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
    mov [0x000000], eax ;
    cmp [0x100000], eax ; In protected mode, A20 should be open and we can thus
    je A20              ; address up to 4GB linear space. (16MB physical mem)
                        ;
                        ; Note it seem that A20 is opened. That's great

    mov eax, main       ; near call in same code seg, absolute indirect via eax
    call eax            ; main is far away from start_32, can't just call main. 

;   test whether keystrike will resuilt in ignore int invoked
breakpoint2:
    nop
    sti  
    int 0x20    

    mov ax, 0
    mov cx, 0
    div cx
    
    jmp $

setup_gdt:
    lgdt [gdt_descr]
    ret

; Gate descriptor: 0~1, 6~7 byte = offset, 2~3 byte = selector, 4~5 = flag
setup_idt:              
    lea edx, [ignore_int]
    mov eax, 0x00080000
    mov ax, dx          ; eax ok
    mov dx, 0x8E00      ; edx ok, gate with dpl = 0, present

    lea edi, [kernel_idt]
    mov ecx, 256

rp_sidt:                ; repeat 256 times to setup int table entries
    mov [edi], eax
    mov [edi + 4], edx
    add edi ,8
    dec ecx
    jnz rp_sidt

    lidt [idt_descr]
    ret

ignore_int:             ; Dummy intterrupt handler that ignore interrupt
    push eax
    push ecx
    push edx
    push ds
    push es
    push fs
    mov ax, 0x10        ; Select kernel data segment descriptor
    mov ds, ax
    mov es, ax
    mov fs, ax
    push int_msg
    call printk
    pop eax
    pop fs
    pop es
    pop ds
    pop edx
    pop ecx
    pop eax
    iret                ; Return from interrupt 

int_msg  db "Unknown interrupt", 0xa, 0xd, 0x0

; *************************ABOVE OVERWRITTEN !!! ***************************
;   code and data in 0x0000 ~ 0x1000 will later be overwritten as page table 
times 4096 - ($ - $$) db 0xAA
times 1024 dd 0x11111111
times 1024 dd 0x22222222
times 1024 dd 0x33333333

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
