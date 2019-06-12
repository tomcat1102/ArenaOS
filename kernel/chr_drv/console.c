/*
*   console.c 6.12    console device
*/

#include "tty.h"
#include "asm/system.h"
#include "asm/port_io.h"

extern void keyboard_interrupt(void);

void con_init(void)
{
    // more to implement here for video memory

    
    set_trap_gate(0x21, keyboard_interrupt); // Set keyboard interrupt handler
    outb(inb(0x21) & 0xfd, 0x21);       // unmask keyboard interrupt signal
    
    unsigned char val = inb(0x61);
    outb(val | 0x80, 0x61);             // disable keyboard and 
    outb(val, 0x61);                    // enable it again
}