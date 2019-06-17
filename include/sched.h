#ifndef SCHED_H
#define SCHED_H

#include <head.h>
#include <mm.h>

#define HZ 100      // Timer interrupt signal every 10ms, our os heartbeat

#define NR_TASKS 64 // Max num of tasks(processes) in the os

// Task can be in one of these states. 
#define TASK_RUNNING            0
#define TASK_INTERRUPTIBLE      1
#define TASK_UNINTERRUPTIBLE    2
#define TASK_ZOMBIE             3
#define TASK_STOP               4

// TSS (Task state segment) structure that saves task state when switching
struct tss_struct
{
    long back_link;         // TSS selector linking to last task
    long esp0, ss0;         // Stack regs for privilege level 0, 1, 2, now
    long esp1, ss1;         // only level 0 is set. Non-modifiable
    long esp2, ss2;         
    long cr3;               // Page dir. Non-modifiable
    long eip;
    long eflags;
    long eax, ecx, edx, ebx;
    long esp;
    long ebp;
    long esi, edi;
    long es, cs, ss, ds, fs, gs;
    long ldt;
    long trace_bitmap;      // I/O bitmap offset from TSS seg
};

// Task truct (aka Process Control Block & Process Descriptor)
// TODO every change task struct, also change INIT_TASK
struct task_struct
{
    long state;             // -1 unrunnable, 0 runnable, >0 stopped
    long counter;           // time slice
    long priority;          // set to counter
    // various other fields. Currently we only use what can be really be used.
    int exit_code;
    // TODO start_code = 0 or 64MB * TASK_INDEX ?
    unsigned long start_code, end_code, end_data, brk, start_stack;
    // task id(process id) and its parent process id
    long pid, father;
    // Accumulated ticks in user-mode, kernel-mode
    long utime, stime;
    // Process start-up time
    long start_time;
    // Local descriptor table. 0-zero 1-cs 2-ds&ss
    struct desc_struct ldt[3];  
    struct tss_struct tss;
};

#define INIT_TASK \
{   0,15,15,0, \
    0,0,0,0,0,\
    0,-1,\
    0,0,\
    0,\
    {{0, 0},{0x9f, 0xc0fa00}, {0x9f, 0xc0f200}},\
    {0, PAGE_SIZE + (long)&init_task, 0x10, 0,0,0,0, (long)&pg_dir,\
    0,0,0,0,0,0,0,0,\
    0,0,0x17,0x17,0x17,0x17,0x17,0x17,\
    _LDT(0), 0x80000000}\
}


// Entries in gdt: 0-nul, 1-cs, 2-ds, 3-nul, 4-tss0, 5-ldt0, 6-tss1 ...
#define FIRST_TSS_ENTRY 4
#define FIRST_LDT_ENTRY (FIRST_TSS_ENTRY + 1)

#define _TSS(n) ((((unsigned long)n) << 4) + (FIRST_TSS_ENTRY << 3))
#define _LDT(n) ((((unsigned long)n) << 4) + (FIRST_LDT_ENTRY << 3))

#define ltr(n)  __asm__("ltr %%ax"::"a"(_TSS(n)))
#define lldt(n) __asm__("lldt %%ax"::"a"(_LDT(n)))

// Get length of segment identified by segment selector
#define get_limit(segment_selector) ({ \
        unsigned long __limit; \
        __asm__("lsll %1, %0; incl %0":"=r"(__limit):"r"(segment_selector)); \
        __limit; })
// Get base of segment identified by segment descriptor in ldt
#define get_base(desc) _get_base((char*)(&desc))
#define _get_base(addr) ({ \
    unsigned long __base; \
    __asm__("movb %3, %%dh;" \
            "movb %2, %%dl;" \
            "shll $16, %%edx;" \
            "movw %1, %%dx;" \
            :"=&d"(__base) \
            :"m"(*((addr) + 2)), "m"(*((addr) + 4)), "m"(*((addr) + 7)) \
            :); \
    __base; \
})
// TODO update Readme.md "gcc inline asm: "=&d" v.s "=d"
/*
break copy_mem
continue
clear copy_mem
*/

// Set base of segment identified by segment descriptor in ldt
#define set_base(desc, base) _set_base(((char*)&(desc)), base)
#define _set_base(addr, base) ({ \
    __asm__("movw %%dx, %0;" \
            "rorl $16, %%edx;" \
            "movb %%dl, %%1;" \
            "movb %%dh, %%2;" \
            ::"m"(*((addr) + 2)), "m"(*((addr) + 4)), "m"(*((addr) + 7)), \
            "d"(base)); \
})



extern struct task_struct *task[NR_TASKS];
extern struct task_struct *current;
extern long volatile jiffies;

#endif // SCHED_H