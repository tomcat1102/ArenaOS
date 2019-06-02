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

    ; Print loading message
    mov bp, MSG_LOAD
    mov cx, 21
    call print

    jmp $

; ------------------------PRINT A C-LIKE STRING--------------------------------
; input: 
;   'bp' address of the null-ended string to be printed
;   'cx' string length
print:
    push ax    
    ; save parameters on stack for later use
    push bp
    push cx
    ; first read cursor position using int 0x10
    mov ah, 0x03    
    xor bh, bh      
    int 0x10        
    ; then print the string at the cursor position
    pop cx          ; string length
    pop bp          ; string address
    mov bx, 0x0007  ; page 0, attribute 7 (normal) 0 black, 1 blue, 2 green ...
    mov ax, 0x1301  ; write string, move cursor
    int 0x10

    pop ax
    ret

; -------------------DATA AREA IN THE BOOTLOADER------------------------------
BOOT_DRIVE:
     db 0x0

MSG_LOAD:
     db 0xa, 0xd            ; new line and carriage return
     db "Loading kernel..."
     db 0xa, 0xd


times 510 - ($ - $$) db 0   ; fill remaining space in the boot sector with 0
dw 0xaa55                   ; boot sector magic number