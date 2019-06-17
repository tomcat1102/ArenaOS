/*
*   Fork.c 6.16
*   Contains helper routines for sys_fork in syscall.asm
*/ 

#include <asm/system.h>
#include <sched.h>
#include <common.h>

long last_pid = 0;  // pid for lastly created task

// Find a unique pid and return an empty slot in 'task' (see sched.c)
int find_empty_process()
{
repeat:    
    if ((++last_pid) < 0) last_pid = 1;
    // Do we have a task with the same pid ? 
    for (int i = 0; i < NR_TASKS; i ++) {
        if (task[i] && task[i]->pid == last_pid) goto repeat;
    }
    // Find an empty slot
    for (int i = 0; i < NR_TASKS; i ++) {
        if (!task[i])
            return i;
    }
    return -1;
}

// Copy page tables. See it in memory.c
extern int copy_page_tables(unsigned long, unsigned long ,unsigned long);

// Copy memory. Used by copy process to copy mem from parent to child process
int copy_mem(int nr, struct task_struct *p)
{
    unsigned long old_code_base, old_data_base;
    unsigned long new_code_base, new_data_base;
    unsigned long code_limit, data_limit;

    // Go through some sanity checks first
    code_limit = get_limit(0x0f);
    data_limit = get_limit(0x17);
    if (data_limit < code_limit) {
        panic("Bad data_limit");
    }

    old_code_base = get_base(current->ldt[1]);
    old_data_base = get_base(current->ldt[2]);
    if (old_code_base != old_data_base) {
        panic("We don't support separate code & data segments");
    }

    // New task obtains its 64MB linear mem addr space starting from nr * 64MB
    new_code_base = new_data_base = nr * 0x4000000; 
    p->start_code = new_code_base;
    
    if (copy_page_tables(old_data_base, new_data_base, data_limit)) {
        panic("copy_page_tables failed");
    }
    return 0;
}

// Copy process. The regs params are already saved on stack.
int copy_process(int nr, long ebp, long edi, long esi, long gs, long none,
    long ebx, long ecx, long edx, long fs, long es, long ds,
    long eip, long cs, long eflags, long esp, long ss)
{
    struct task_struct *p = (struct task_struct *)get_free_page();
    if (!p) return -1;

    task[nr] = p;
    // Copy parent process task struct to the child's
    for(int i = 0; i < sizeof(struct task_struct); i ++)
        p[i] = current[i];

    // Set specific field in child's task struct that's different from parent's
    p->state = TASK_UNINTERRUPTIBLE;
    p->pid = last_pid;
    p->father = current->pid;
    p->counter = p->priority;   // reset counter to its priority
    p->utime = p->stime = 0;    // reset time ticks to zero
    p->start_time = jiffies;

    // Set specific fields of tss in child's task struct
    struct tss_struct *p_tss = &(p->tss);
    p_tss->back_link = 0;
    p_tss->esp0 = (long)p + PAGE_SIZE;
    p_tss->ss0 = 0x10;
    p_tss->eip = eip;
    p_tss->eflags = eflags;
    p_tss->eax = 0;             // So child process return 0 from fork()
    p_tss->ecx = ecx;
    p_tss->edx = edx;
    p_tss->ebx = ebx;
    p_tss->esp = esp;
    p_tss->ebp = ebp;
    p_tss->esi = esi;
    p_tss->edi = edi;
    p_tss->es = es & 0xffff;
    p_tss->cs = cs & 0xffff;
    p_tss->ss = ss & 0xffff;
    p_tss->ds = ds & 0xffff;
    p_tss->fs = fs & 0xffff;
    p_tss->gs = gs & 0xffff;
    p_tss->ldt = _LDT(nr);
    p_tss->trace_bitmap = 0x80000000;

    if (copy_mem(nr, p)) {
        task[nr] = NULL;
        free_page((long)p);
        panic("copy_mem: failed");
    }

    set_tss_desc(kernel_gdt + FIRST_TSS_ENTRY + (nr << 1), &(p->tss));
    set_ldt_desc(kernel_gdt + FIRST_LDT_ENTRY + (nr << 1), &(p->ldt));

    p->state = TASK_RUNNING;  // now task 1 is ready to be scheduled
    return last_pid;
}