/*
*   Sched.c 6.12   kernel scheduling part
*/
#include <asm/port_io.h>
#include <asm/system.h>
#include <sched.h>
#include <mm.h>
#include <head.h>

// The 8253 programmable interval timer oscilates at 1193180 times per sec,
// so for the PIT to generate 100 timer interrupt per second, it has to 
// oscilate 1193180 / 100 times per interval before generating an interrupt.
#define LATCH (1193180 / HZ)

extern void timer_interrupt(void);
extern void system_call(void);

// Time
long startup_time = 0;          // kernel startup time since 1970:0:0:0
long volatile jiffies = 0;      // heartbeats since kernel starts 

// Task
union task_union {              // task struct & stack space for task 0
    struct task_struct task;    // the union size should be one page size, 4096
    char stack[PAGE_SIZE];
};
static union task_union init_task = {INIT_TASK}; // task 0, first task in our os

long user_stack[PAGE_SIZE >> 2];                 // user mode stack for task 0
struct {                        // stack descriptor for task 0's user mode stack
    long *esp;
    short ss;
} __attribute__((packed)) stack_start = { &user_stack[PAGE_SIZE >> 2], 0x10};

struct task_struct *task[NR_TASKS] = {&(init_task.task)}; // max of 64 task slot
struct task_struct *current = &(init_task.task);

// Init first task, timer. Set timer interrupt hanler and the entry routine that 
// handles all system calls.
void sched_init(void)
{
    // Set first task's descriptors in gdt
    set_tss_desc(kernel_gdt + FIRST_TSS_ENTRY, &(init_task.task.tss));
    set_ldt_desc(kernel_gdt + FIRST_LDT_ENTRY, &(init_task.task.ldt));
    // No need to clear 'kernel_gdt[256]' and 'task[NR_TASKS]' as in linux 0.11. 


    // Clear NT flags, no worry about Nested Task
    __asm__("pushfl; andl $0xffffbfff, (%esp); popfl");

    // Load first task's descriptors to tr and ldt regs
    ltr(0);
    lldt(0); 

    // Initialize timer
    outb_p(0x36, 0x43);           
    outb_p(LATCH & 0xff, 0x40);  // Set timer port 0x43 to binar mode 3 LSB/MSB
    outb(LATCH >> 8, 0x40);     // Send the LATCH
        
    // Set timer interrupt handler & Unmask timer interrupt signal
    set_intr_gate(0x20, timer_interrupt);
    outb(inb(0x21) & ~0x01, 0x21);

    // Set system call entry
    set_system_gate(0x80, system_call);
}