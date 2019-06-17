; System_call.asm 6.12
;
; Contains system-call low-level handling routines. Also contains some interrupt
; handlers cause I don't wanna create more asm files. It's good to put them here

; Stack offset relative to current esp after saving ret val from syscall
; We have to prefix them with underscore '_', or assembler won't compile
_EAX     equ 0x00
_EBX     equ 0x04
_ECX     equ 0x08
_EDX     equ 0x0C
_FS      equ 0x10
_ES      equ 0x14
_DS      equ 0x18
_EIP     equ 0x1C
_CS      equ 0x20
_EFLAGS  equ 0x24
_ESP     equ 0x28
_SS      equ 0x2C

[bits 32]
global timer_interrupt
global system_call
global syscall_table

extern jiffies
extern find_empty_process
extern copy_process

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
    push eax            ; Save ret val from syscall 
ret_from_syscall:
                        ; TODO signal handling, check need reschedule?

    pop eax             ; Restore ret val in eax                    
    pop ebx
    pop ecx
    pop edx
    pop fs
    pop es
    pop ds
    iret

; some syscall entries are defined here. However, the real shit is in .c files.
sys_fork:
    call find_empty_process     ; See fork.c. Return negative eax if not found.
    test eax, eax               ; 'test' reserve eax value and if both are neg,
    js _sys_fork_end            ; sign flag will be set and 'js' will jump.
    push gs
    push esi
    push edi
    push ebp
    push eax                    ; Save regs on stack that haven't been saved 
    call copy_process           ; for use by copy_process()
    add esp, 20
_sys_fork_end:                  ; Note after return from copy_process(), eax 
    ret                         ; contains child process's pid (shouldn't be 0)

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
; For any regs modified herein, we mush save them to avoid any potential bug
timer_interrupt:
    push ds         ; Save regs as if it were a system call, so later we can 
    push es         ; jmp to ret_from_syscall and restore regs normally.
    push fs
    push edx
    push ecx
    push ebx
    push eax        ;push one more val to balance,it's like ret val from syscall
    mov eax, 10     ; update ds, es & fs properly
    mov ds, ax
    mov es, ax
    mov eax, 17
    mov fs, ax

    inc dword [jiffies] ; increase system ticks 
    mov eax, 0xDEADFADE

    mov al, 0x20
    out 0x20, al    ; Send EOI to 8259


    jmp ret_from_syscall