#include "mm.h"

// user mode stack for task 0
long user_stack[PAGE_SIZE >> 2];
struct {
    long *esp;
    short ss;
} __attribute__((packed)) stack_start = { &user_stack[PAGE_SIZE >> 2], 0xFB};

long variable = 0xDDCCBBAA;

void print();

int main() {
    //long *esp = stack_start.esp;
    long address = (long)&variable;
    long val = 0xAAAABBBB;
    user_stack[PAGE_SIZE>>2] = 0xEFBEcccc;
    print();
    return val;
}

// TODO C linkage. Code seems good, but addresses of global data are bad
// Need test code, and then data address !!!