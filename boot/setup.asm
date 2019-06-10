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

    ; Check if disk 1 exists
    mov ah, 0x15
    mov dl, 0x81
    int 0x13
    jc  no_disk1
    cmp ah, 3       ; Is it a fixed disk, not diskette ?
    je  is_disk1
no_disk1:           ; clear disk 1 info if the disk is not available
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

    
    cli             ; disable interrupts

    ; Move kernel to 0x00000.

    ; Actually we move whatever in 0x10000 ~ 0x90000 to 0x0000 ~ 0x80000, each 
    ; time we move 64KB so as not to cross segment boundary.
    ; BIOS int table at 0x00000 will be overwritten, however, we no longer need 
    ; it. Later we'll set up our own interrupt table in 32bit protected mode.

    mov ax, 0x0000
    cld                 ; clear direction flag, move forward
do_move:                
    mov es, ax
    add ax, 0x1000
    cmp ax, 0x9000      ; is move over ?
    je  end_move
    mov ds, ax
    xor di, di
    xor si, si
    mov cx, 0x8000      ; 64KB
    rep movsw
    jmp do_move

end_move:
    mov ax, SETUP_SEG   ; I forget this, made the same mistake as that of Linus
    mov ds, ax          ; in Linux 0.11

    lgdt [gdt_48]       ; Load temporary gdt & idt descriptor before entering 
    lidt [idt_48]       ; protected mode. Reset them later in head.asm

                        ; Reprogram 8259 Interrupt controller. Intel-reserved
                        ; CPU internal interrupts occupy 0x00 to 0x1f (32 ints),
                        ; we replace our external 15 intterupts to 0x20 to 0x2f.
    mov al, 0x11
    out 0x20, al        ; initializatin sequence to 8259A-1 port 0x20
    out 0xA0, al        ; and to 8259A-2
    mov al, 0x20
    out 0x21, al        ; starting interrupt number 0x20 for 8259A-1
    mov al, 0x28
    out 0xA1, al        ; starting interrupt number 0x28 for 8259A-1
    mov al, 0x04
    out 0x21, al        ; 8259A-1 is master interrupt chip
    mov al, 0x02
    out 0xA1, al        ; 8259A-2 is slave interrupt chip
    mov al, 0x01
    out 0x21, al        ; 8086 mode for both chips
    out 0xA1, al
    mov al, 0xff
    out 0x21, al        ; mask off all interrupts
    out 0xA1, al


    mov ax, 0x0001
    lmsw ax             ; set PE flag, enable Protected Mode

    jmp 8:0    ; 32bit world is waiting for us, let's jump into it!

%include "print.asm"

MSG_SETUP_OK:
    db "Setup ok, entering protected mode..."
    db 0xa, 0xd

gdt_start:
    ; dummy segment selector
    dw 0, 0, 0, 0       

    ; code segment selector
    dw 0x07FF           ; 8MB = 2048 * 4KB, segment length
    dw 0x0000           ; 0x00000 = segment base
    db 0x00, 0x9A       ; 0x00 = segment base, 0x9A = code read/exec
    db 0xC0, 0x00       ; 0xC = 4 flag bits, gran=4096, 386, 
                        ; 0x0 = segment length, 0x00 = segment base
    ; data segment selector
    dw 0x07FF           ; 8MB = 2048 * 4KB, segment length
    dw 0x0000           ; 0x00000 = segment base
    db 0x00, 0x92       ; 0x00 = segment base, 0x92 = data read/write
    db 0xC0, 0x00       ; 0xC = 4 flag bits, gran=4096, 386, 
gdt_end:                ; 0x0 = segment length, 0x00 = segment base


gdt_48:
    dw gdt_end - gdt_start
    dd 0x90200 + gdt_start

idt_48:
    dw 0x01
    dd 0x0000

times 512 - ($ - $$) db 0 ; fill this sector with 0

