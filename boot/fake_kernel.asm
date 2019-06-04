; This file fakes a kernel and is apppended after boot sector, setup sector and 
; head.asm. The size is deliberately set to about 150KB so as to test whether
; code in boot_sector can load the 'big' kernel and safely cross 64KB boundary.
times 512 * 49 db 0xA0
times 512 * 63 db 0xB2
times 512 * 63 db 0xC3
times 512 * 63 db 0xD4
times 512 * 63 db 0xE5
