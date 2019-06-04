#include "mm.h"


// user mode stack for task 0
long user_stack[PAGE_SIZE >> 2];
struct {
    long *esp;
    short ss;
} __attribute__((packed)) stack_start = { &user_stack[PAGE_SIZE >> 2], 0xFB};

void print();

void _start() {
    print();
}

