; System_call.asm 6.12
;
; Contains system-call low-level handling routines. Also contains some interrupt
; handlers cause I don't wanna create more asm files. It's good to put them here
[bits 32]
global timer_interrupt
global system_call
global syscall_table
extern jiffies

nr_system_calls equ 4   ; Number of system calls in ArenaOS

bad_sys_call:
    mov eax, -1         ; Set return val -1 in eax
    iret

; All system calls first go through this entry
system_call:
    cmp eax, nr_system_calls
    ja bad_sys_call
    push ds             ; Save segment regs (should all be 0x001f)
    push es
    push fs
    push edx            ; Save params to system call (ebx, ecx & edx)
    push ecx
    push ebx
    mov edx, 0x10       ; Update ds, es to points to kernel data segment
    mov ds, dx          ; Don't use eax since it contains syscall number
    mov es, dx
    mov edx, 0x17       ; Update fs to points to user data segment, since data  
    mov fs, edx         ; may need to be moved between kernel and user space

    call [syscall_table + eax * 4]  

    pop ebx
    pop ecx
    pop edx
    pop fs
    pop es
    pop ds
    iret

; some syscall entries are defined here. However, the real shit is in .c files.
sys_fork:
    nop
    nop
    mov eax, 0
    ret

sys_dummy:
    nop
    nop
    mov eax, -1
    ret

; TODO Change nr_system_calls if needed
syscall_table:
    dd sys_dummy    ; 0-setup()
    dd sys_dummy    ; 1-exit()
    dd sys_fork     ; 2-fork()
    dd sys_dummy    ; 3-read() 

; int32 (int 0x20)
timer_interrupt:
    nop 
    nop 
    inc dword [jiffies]
    mov eax, 0xDEADFADE

    mov al, 0x20
    out 0x20, al       ; Send EOI to 8259

    iret