/*
*   Fork.c 6.16
*   Contains helper routines for sys_fork in syscall.asm
*/ 

#include <sched.h>

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