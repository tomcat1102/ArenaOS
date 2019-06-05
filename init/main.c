#include "mm.h"

// user mode stack for task 0
long user_stack[PAGE_SIZE >> 2];
struct {
    long *esp;
    short ss;
} __attribute__((packed)) stack_start = { &user_stack[PAGE_SIZE >> 2], 0x10};

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

