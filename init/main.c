#include "asm/system.h"
#include "asm/port_io.h"
#include "mm.h"

extern int printk();
extern void trap_init(void);

#define EXT_MEM_K       (*(unsigned short*)0x90002)
#define DRIVE_INFO_P    ((struct drive_info*)0x90080)
#define ORIG_ROOT_DEV   (*(unsigned short*)0x901FD)

struct drive_info {
    char i[32];
} drive;

// user mode stack for task 0
long user_stack[PAGE_SIZE >> 2];

struct { 
    long *esp;
    short ss;
} __attribute__((packed)) stack_start = { &user_stack[PAGE_SIZE >> 2], 0x10};

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
    // due to dependency. memory should be init first!

    // mem_init()   ; init main memory area
    trap_init();    //init trap gates and some system gates

    // sti() just change interrupt flag in eflags
    // however, we still need to unmask interrupt bits in 8259 status ports
    sti(); 

    // Fake a divide by 0 exception to test whether the handler works !
    __asm__("movl $0, %%edx; movl $8, %%eax; movl $0, %%ecx; div %%ecx"::);

    // TODO port read & write defines out
    int a = 10;
    unsigned char p21 = inb(0x21);
    unsigned char pA1 = inb(0xA1);

    // TODO chr_drv, directory output is single archive file
    // avoid linking all objs, some can be archive obj file

    nop();
    nop();
}

