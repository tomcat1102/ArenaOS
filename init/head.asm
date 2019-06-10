;   head.s -- head of the kernel. 6.3

%include "../boot/boot.inc"

[bits 32]
global startup_32
extern stack_start
extern main
extern printk

pg_dir:
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

                        ; Setup parameters for main()
    push 0xFADE         ; env
    push 0x7            ; argv 
    push 0xDEED         ; argc
    push 0              ; dummy ret addr, note main() never returns
    push main           ; After setup_page() returns, it goes to main() :)
                   
    jmp setup_paging    ; Seems that A20 is opened. Great! Now enable paging.
    
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

ignore_int:             ; Dummy intterrupt handler that ignores interrupt
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
pg0:  times 1024 dd 0x11111111
pg1:  times 1024 dd 0x22222222
pg2:  times 1024 dd 0x33333333
pg3:  times 1024 dd 0x44444444

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

; setup_paging shouldn't be overwritten for page table. 
; It can't clear itself, so it's placed here after page table and gdt & idt.
setup_paging:           
    mov ecx, 1024*5     ; clear page table in first 20kB
    xor eax, eax
    xor edi, edi
    cld
    rep stosd

        ; Set first 4 pg_dir entris that cover 16MB mem, 7 = page preset, r/w.
    mov word [pg_dir + 0], pg0 + 7
    mov word [pg_dir + 4], pg1 + 7
    mov word [pg_dir + 8], pg2 + 7
    mov word [pg_dir + 12], pg3 + 7
        ; Set page entries in each page table backwardly, from last page in pg3.
    mov edi, pg3 + 4092 
    mov eax, 0xfff007   ; = 0x100000 - 4096 + 7(page attr)

    std
setup_page:
    stosd
    sub eax, 0x1000     ; subtract a page size
    jge setup_page

                        ; Enable paging via cr0 & cr3 register
    xor eax, eax
    mov cr3, eax        ; cr3 -> address of page table
    mov eax, cr0            
    or eax, 0x80000000
    mov cr0, eax        ; cr0 -> set PG bit 31

breakpoint:
    nop
    nop
    nop

    ret                 ; will return to C main()


