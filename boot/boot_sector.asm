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
    mov [boot_drive], dl    ; dl should be 0x80 if booted from hard disk


    ; Load setup sector in 0x90200 right after the boot sector 
load_setup:    ; TODO modify SETUP_LEN if need to
    mov ax, 0x0200 + SETUP_LEN  ; ah: read, al: nr sectors to read
    mov dh, 0x00                ; dh: head
    mov dl, [boot_drive]        ; dl: drive
    mov cx, 0x0002              ; ch: track, cl: starting sector 
    mov bx, 0x0200              ; bx: read to es:bx
    int 0x13
    jnc end_load_setup
    ; Just in case there is load error, try at most LOAD_TRY(3) times. 
    ; However, this cannot happen normally after testing
    dec byte [load_try]
    cmp byte [load_try], 0
    jg load_setup

    mov bp, msg_bad_load
    mov cx, 18
    call print
end_load_setup:


    ; ***************** Prepare to load kernel ******************************
    mov bp, msg_load_kernel
    mov cx, 19
    call print

    ; we need to know nr of sectors/track cause we aren't just loading a sector
    ; from the kernel, but the whole kernel whose size may reach up to 512Kb.

    mov dl, [boot_drive]
    mov ah, 0x08
    int 0x13

    and cl, 00111111b   
    mov [sectors], cl

    ; set read destination to es:bx, 0x10000
    mov ax, SYS_SEG
    mov es, ax
    xor bx, bx      

rp_read:
    mov ax, es
    cmp ax, END_SEG
    jb  ok1_read
    jmp end_load_kernel
ok1_read:
    mov ax, [sectors]   ; ax: nr sectors per track
    sub ax, [sread]     ; ax: sectors to read in current track
    mov cx, ax          ; cx = ax
    shl cx, 9           ; cx: bytes read for ax sectors
    add cx, bx          ; cx: new segment offset after reading cx bytes at bx
    jnc ok2_read        ; segment not cross 64KB boundary, read the track
    je  ok2_read        
    xor ax, ax          ; segment will cross boundary, read as much as posiible
    sub ax, bx          ; ax: bytes to read at most without crossing
    shr ax, 9           ; ax: sectors to read at most without crossing
ok2_read:
    call read_track
    mov cx, ax          ; cx: sectors read
    add ax, [sread]     ; ax: sector number in current track
    cmp ax, [sectors]   ; is the whole track in current head read ?
    jne ok3_read
    mov ax, 0           ; next read starts at first sector
    inc word [head]     ; yes, read the track in next head
    cmp word [head], 15      
    jl ok3_read         ; if not last head, ok
    mov word [head], 0  ; if last head, read the next track on head 0
    inc word [track]
ok3_read:
    mov [sread], ax     ; save sread
    shl cx, 9           ; cx: bytes read
    add bx, cx          ; bx: new segment offset 
    jnc rp_read
    mov ax, es          ; if 64 KB, adjust es:bx
    add ax, 0x1000
    mov es, ax
    xor bx, bx
    jmp rp_read

read_track:             ; in ax: sectors to read
    push ax
    push bx
    push cx
    push dx

    mov dx, [track]      
    mov cx, [sread]
    inc cx              ; cl: 5~0 starting sector number
    mov ch, dl          ; ch: track number
    mov dx, [head]
    mov dh, dl          ; dh: head number
    mov dl, [boot_drive]; dl: drive number
    mov ah, 0x2         ; AH: 2, read
    int 0x13
    jc bad_read

    pop dx
    pop cx
    pop bx
    pop ax
    ret

bad_read:
    nop
    mov ax, cs
    mov es, ax
    mov bp, msg_bad_load
    mov cx, 18
    call print 
    jmp $

    ; ************************Kernel load finished **************************
end_load_kernel:
    jmp SETUP_SEG:0000
    jmp $

%include "print.asm"

; -------------------DATA AREA IN THE BOOTLOADER------------------------------
; Variables needed to record infomation for loading kernel image
load_try    db 0x3
sectors     dw 0x0
sread       dw 0x1 + SETUP_LEN
head        dw 0
track       dw 0

msg_load_kernel db "Loading kernel...", 0xa, 0xd ; new line and carriage return
msg_bad_load    db "Fatal load error", 0xa, 0xd
   

times 509 - ($ - $$) db 0   ; fill remaining space in the boot sector with 0
boot_drive  db 0x0          ; put boot drive number at a known address
dw 0xaa55                   ; boot sector magic number