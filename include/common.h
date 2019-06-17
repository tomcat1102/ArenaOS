#ifndef COMMON_H
#define COMMON_H

/*
*   Common.h 6.16
*/

// function declarations that are often used throughout kernel
void panic(const char* str);
unsigned long get_free_page();
void free_page(unsigned long addr);

#ifndef NULL
#define NULL ((void*)0)
#endif//NULL

#endif//COMMON_H