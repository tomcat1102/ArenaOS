#ifndef PORT_IO_H
#define PORT_IO_H
/*
*   port_io.h 6.12 
* 
*   Defines for assembly code that read & write system io ports
*/

#define outb(value, port) \
    __asm__("outb %%al, %%dx"::"a"(value), "d"(port))

#define outb_p(value, port) \
    __asm__("outb %%al, %%dx;" \
    "   jmp 1f;" \
    "1: jmp 1f;" \
    "1: " \
    ::"a"(value), "d"(port))

#define inb(port)({\
    unsigned char val;\
    __asm__ volatile ("inb %%dx, %%al":"=a"(val):"d"(port));\
    val;\
})

#endif // PORT_IO_H