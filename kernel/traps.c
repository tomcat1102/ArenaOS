#include <asm/system.h>
#include <asm/port_io.h>

void divide_error(void);

// Fill idt with trap gates
//  0 -16: trap gates for CPU exceptions.
//  16-32: Intel-reserved, will print 'Unknown Interrupt" if generated.
//  32-48: temporty trap gate for 8259 Interrrupt chip, set to function 
//         'reserved', reinstalled as interrrup gate later by correponding 
//          hardware initialization routines.
//
// Note that the 0x21 & 0xA1 ports are partly reset to enable irq13 interrupt
// signal from slave chip to master chip.

void trap_init(void)
{
    set_trap_gate(0, divide_error);


    // unmask irq2 of master 8259
    outb(inb(0x21) & 0xfb, 0x21);   // 0xfb = 11111011, which means the third 
                                    // bit (IRQ2) is set to zero, thus enabled
}