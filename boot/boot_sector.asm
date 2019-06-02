;  ArenaOS boot loader. 5.31

; 0x100 = 256B
; 0x400 = 1KB
; 0x1000 = 4KB
; 0x10000 =  64KB
; 0x90000 = 576KB  
; 0xA0000 = 640KB (640KB ~ 1MB is for BIOS rom and video ram) 
; 0x100000 = 1MB 

%include "boot.inc"

[bits 16]
global _start

_start:
    ; Move boot sector from 0x7c00 to 0x9000, 64 KB way before BIOS & video ram.
    mov ax, BOOT_SEG    ; move from 'ds:si' to 'es:di'
    mov ds, ax
    mov si, 0           
    mov ax, INIT_SEG    
    mov es, ax
    mov di, 0
    mov cx, 256         ; move count 256 words = 512 bytes
    rep movsd

    ; Jump to the new location and continue execution after move
    jmp INIT_SEG:go

    ; Setup proper segment regs
go: mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFF00      ; stack top at 0x9FF00

    ; Save boot drive from BIOS. 
    ; 'dl' stores boot drive number after BIOS transfered the control to our 
    ; bootloader. Since 'dl'may be changed later, it should be saved asap.
    mov [BOOT_DRIVE], dl    ; dl should be 0x80 if booted from hard disk


    ; Load setup sector in 0x90200 right after the boot sector 
load_setup:    ; TODO modify SETUP_LEN if need to
    mov ax, 0x0200 + SETUP_LEN  ; ah: read, al: nr sectors to read
    mov dh, 0x00    ; 
    mov dl, [BOOT_DRIVE]
    mov cx, 0x0002
    mov bx, 0x0200
    int 0x13
    jnc ok_load_setup
    ; Just in case there is load error, try at most LOAD_TRY(3) times. 
    ; However, this cannot happen normally after testing
    dec byte [LOAD_TRY]
    cmp byte [LOAD_TRY], 0
    jg load_setup

    mov bp, MSG_BAD_LOAD
    mov cx, 18
    call print
    jmp $

ok_load_setup:

    ; Now load the kernel
    mov bp, MSG_LOAD_KERNEL
    mov cx, 19
    call print

    ; ... load the kernel

    jmp SETUP_SEG:0000

    jmp $

%include "print.asm"

; -------------------DATA AREA IN THE BOOTLOADER------------------------------
BOOT_DRIVE:
    db 0x0
LOAD_TRY: 
    db 0x3    

MSG_LOAD_KERNEL:
    db "Loading kernel...", 0xa, 0xd ; new line and carriage return
MSG_BAD_LOAD:
    db "Fatal load error", 0xa, 0xd

    

times 510 - ($ - $$) db 0   ; fill remaining space in the boot sector with 0
dw 0xaa55                   ; boot sector magic number