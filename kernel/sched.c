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

void schedule()
{
    struct task_struct **p; // points to task slot
    int idx;                // idx into task slot
    int target;             // idx of target task to switch to 
    int counter;            // max counter found in tasks, which need schedule

    while (1) {             // Loop until we find the task with biggest counter
        // Reinitialized these each time loop
        p = &task[NR_TASKS];
        idx = NR_TASKS;      
        target = 0;
        counter = -1;

        while (--idx) {
            if (! *(--p))   // skip empty task slot
                continue;
            // Set target if current task is 'running' with bigger counter. Note 
            // that bigger connter implies that the task hasn't been running 
            // very often, so we should switch to it to let it run.
            if ((*p)->state == TASK_RUNNING && (*p)->counter > counter) {
                target = idx;
                counter = (*p)->counter;
            }

            // We found a task with biggest non-zero counter to run, switch!
            if (counter) break; 

            // Since all tasks have no counter or not runnable, reset them
            // formula: 
            //      new_counter = current_conuter /2 + priority
            //
            // This way, if a task is sleeping, its counter will matter and 
            // account half to its new counter. So when it wakes up and ready
            // to run, it can run a bit longer. Besides these sleeping task,
            // the running task will have their new counter reset to its
            // priority, so the task with biggest priority will run first.

            for (p = &LAST_TASK; p > &FIRST_TASK; p --) {
                if (*p) {
                    (*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
                }
            }
        }

        switch_to(target);
    }
}

// Invoked at every system tick in timer_interrupt of syscall.asm
// It accumulate ticks for task and reschedule if run out of time slice
void do_timer(long cpl)
{
    if (cpl) {              // accumulate ticks for task in user or kernel mode
        current->utime ++;  // however, I find it not very accurate.
    } else {
        current->stime ++;
    }

    if ((--current->counter) > 0) return;   // return if it still has time slice
    current->counter = 0;       // counter may be less thant 0, reset it to 0
    if (!cpl) return;           // Note we don't reschedule as it is non-
    schedule();                 // preemptive in kernel mode!
}