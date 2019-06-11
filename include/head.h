#ifndef HEAD_H
#define HEAD_H

// Dummy type for gdt & idt
typedef struct desc_struct {
    unsigned long a, b;
} desc_table[256];           

extern desc_table kernel_gdt;
extern desc_table kernel_idt;

#endif // HEAD_H