; Setup sector. 5.2

%include "boot.inc"

[bits 16]
global _setup

_setup:
    ; Save various information for later use
    mov ax, INIT_SEG
    mov ds, ax

    ; 0x90000: cursor column
    ; 0x90001: cursor row
    ; 0x90002: extended memory size (memory after 1MB)     
    ; 0x90004: display attribute
    ; 0x90005: current display page
    ; 0x90006: current mode
    ; 0x90007: nr screen column
    ; 0x90008: ??
    ; 0x9000A: EGA memory size
    ; 0x9000B: color or mono mode in effect
    ; 0x9000C: video switch settings
    ; 0x9000D: video feature bits

    ; 0x90080-0x9008F: disk 0 info
        ;-OFF---SIZE----DESCRIPTION--------
        ; 00    word    max nr cylinders    
        ; 02    byte    max nr heads
        ; 03    word    starting reduced write current cylinder ?
        ; 05    word    starting write pre-comp cylinder ?
        ; 07    byte    max ECC data burst length ?
        ; 08    byte    control byte: ... ?
    ; 0x90090-0x9009F: disk 1 info
        ; same as disk 0


    ; Save cursor position
    mov ah, 0x03
    mov bh, 0
    int 0x10
    mov [0], dx     
    ; Save mem size
    mov ah, 0x88
    int 0x15
    mov [2], ax     
    ; Save video state
    mov ah, 0x0f
    int 0x10
    mov [4], bx     
    mov [6], ax     
    ;  Save EGA/VGA configuration
    mov ah, 0x12
    mov bl, 0x10
    int 0x10
    mov [8], ax ; ??
    mov [10], bx
    mov [12], cx

    ; Save disk 0 info 
    mov ax, 0x0000
    mov ds, ax          ; pointer to the info is stored at BIOS Int table 0x41
    lds si, [4 * 0x41]  ; load the pointer -> ds:si
    mov ax, INIT_SEG
    mov es, ax
    mov di, 0x0080      ; destination -> es:di
    mov cx, 0x10        ; move 16 bytes
    rep movsb           

    ; Save disk 1 info
    mov ax, 0x0000
    mov ds, ax
    lds si, [4 * 0x46]
    mov ax, INIT_SEG
    mov es, ax
    mov di, 0x0090
    mov cx, 0x10
    rep movsb

    ; Check if disk 1 exists, and clear its info if not available (should do)
    mov ah, 0x15
    mov dl, 0x81
    int 0x13
    jc  no_disk1
    cmp ah, 3       ; Is it a fixed disk, not diskette ?
    je  is_disk1
no_disk1:
    mov ax, INIT_SEG
    mov es, ax
    mov di, 0x0090
    mov cx, 0x10
    mov al, 0x00
    rep stosb       ; clear cx(16) bytes in es:di(0x90090) with al(0)
is_disk1:

    ; Print a message and prepare to enter procted mode
    mov ax, cs
    mov es, ax
    mov bp, MSG_SETUP_OK
    mov cx, 38
    call print

breakpoint:
    jmp $

%include "print.asm"

MSG_SETUP_OK:
    db "Setup ok, entering protected mode..."
    db 0xa, 0xd

;times 512 - ($ - $$) db 0 ; fill this sector with 0

