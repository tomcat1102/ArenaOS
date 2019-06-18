#ifndef COMMON_H
#define COMMON_H

/*
*   Common.h 6.16
*/

// defines
#ifndef NULL
#define NULL ((void*)0)
#endif

// function declarations 
void panic(const char* str);
unsigned long get_free_page();
void free_page(unsigned long addr);

// varible declaratiosn
extern struct task_struct *current;


#endif//COMMON_H