#include <asm/system.h>
#include <asm/port_io.h>
#include <mm.h>

// Define __LIBRARY__ for syscall invocation with inline assembly in unistd.h
#define __LIBRARY__     
#include <unistd.h>   
// when fork() from task 0 to get init() running, we can't touch stack as that 
// would cause 'Copy on Write'. However since calling fork() and pause() would
// use stack, we mush avoid this by calling them with inline assembly.
static __attribute__((always_inline)) __syscall0(int, fork);
#undef __LIBRARY__
// Add fork() declaration again to suppress compiler warning
static inline int fork(void);

extern int printk();
extern void mem_init(long, long);
extern void trap_init(void);
extern void tty_init(void);
extern void time_init(void);
extern void sched_init(void);
void init(void);

// Some Infomation from setup.asm
#define EXT_MEM_K       (*(unsigned short*)0x90002)
#define DRIVE_INFO_P    ((struct drive_info*)0x90080)
#define ORIG_ROOT_DEV   (*(unsigned short*)0x901FD)

// HD drive
struct drive_info {     // Save 32 byte hard disk info from setup.asm
    char i[32];
} drive;

/* Memory layout:
 * [0 - ?]              : mem for kernel, ? less than 640KB
 * [? - 640KB]          : mem for fs cache
 * [640KB - 1MB]        : reserved for BIOS and video ram
 * [1MB - mem_beg]      : mem for fs cache       
 * [mem_beg - mem_end]  : main memory area
 */

static long mem_beg = 0;  
static long mem_end = 0;

void main(int argc, char *argv[], char* env[]) {
    printk(); 
    // ROOT_DEV = ORIG_ROOT_DEV ; super.c, load file system from ROOT_DEV

    // Save drive information
    for(int i = 0; i < 32; i ++)
        drive.i[i] = DRIVE_INFO_P->i[i];

    // Determine memory layout based on available memory size
    mem_end = (1 << 20) + (EXT_MEM_K << 10);
    mem_end &= 0xffff0000;              // round to page size
    if (mem_end > 16 * 1024 * 1024) 
        mem_end = 16 * 1024 * 1024;     // max supported mem size 16MB

    if (mem_end > 12 * 1024 * 1024) {
        mem_beg = 4 * 1024 * 1024;     
    } else if (mem_end > 6 * 1024 * 1024) {
        mem_beg = 2 * 1024 * 1024;
    } else {
        mem_beg = 1 * 1024 * 1024;
    }
    
    // Init different parts of kernel, note some parts should be inited first 
    // due to dependency. E.g. mem_init() should be init first, sched_init() 
    // must be after time_init().

    mem_init(mem_beg, mem_end);     // init main memory area    
    trap_init();                    // init trap gates and some system gates
    tty_init();                     // init tty devices and related interrupts
    time_init();                    // set kernel startup 
    sched_init();                   // init sched and prepare first task

    // sti() just change interrupt flag in eflags
    // however, we still need to unmask interrupt bits in 8259 status ports
    sti(); 

    move_to_user_mode();

    // TODO implement fork() in fork.c
    if (fork()) {
        init();
    }

    nop();
    nop();

    while(1);
}

void init()
{

}

