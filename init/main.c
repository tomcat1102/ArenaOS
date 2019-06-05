#include "mm.h"

// user mode stack for task 0
long user_stack[PAGE_SIZE >> 2];
struct {
    long *esp;
    short ss;
} __attribute__((packed)) stack_start = { &user_stack[PAGE_SIZE >> 2], 0xFB};

long variable = 0xDDCCBBAA;

void print();

void main() {
    //long *esp = stack_start.esp;
    long address = (long)&variable;
    long val = 1;
    print();
}

// TODO C linkage. Code seems good, but data(user_stakc) address is bad
// Need test code, and then data address !!!