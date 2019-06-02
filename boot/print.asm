; ------------------------PRINT A C-LIKE STRING--------------------------------
; input: 
;   'bp' address of the null-ended string to be printed
;   'cx' string length
print: ;                        ; TODO print should scrool if no space is left
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
    