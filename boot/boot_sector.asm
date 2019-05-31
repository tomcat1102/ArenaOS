;   ArenaOS boot sector. 5.31

; 0x100 = 256B
; 0x400 = 1KB
; 0x1000 = 4KB
; 0x10000 =  64KB
; 0x90000 = 576KB  
; 0xA0000 = 640KB (640KB ~ 1MB is for BIOS rom and video ram) 
; 0x100000 = 1MB 

BOOT_SEG equ 0x07c0
INIT_SEG equ 0x9000


[bits 16]
global _start
global BOOT_DRIVE

_start:
    ; Move boot sector from 0x7c00 to 0x9000, just before BIOS & video ram area.
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

    ; Setup segment regs after move
go: mov ax, cs
    mov ds, ax
    mov es, 

    ; Save boot drive from BIOS. 
    ; 'dl' stores boot drive number after BIOS transfered the control to our 
    ; bootloader. since 'dl'may be changed later, it should be saved asap.
go: mov ax, cs              
    mov ds, ax              ; change 'ds' to new 0x9000
    mov [BOOT_DRIVE], dl    ; dl should be 0x80 since BIOS booted from hard disk

    jmp $

BOOT_DRIVE db 0x0

times 510 - ($ - $$) db 0   ; fill remaining space in the boot sector with 0
dw 0xaa55                   ; boot sector magic number