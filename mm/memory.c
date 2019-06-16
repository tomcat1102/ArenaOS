/*
*   Memory.c 6.16
*/
#include <common.h>

// See memory layout in main.c and head.s
#define LOW_MEM         0x100000
#define PAGING_MEMORY   (15 * 1024 * 1024)    
#define PAGING_PAGES    (PAGING_MEMORY >> 12)

// Convert physicall address to index in mem_map[].
#define MAP_NR(paddr) (((paddr) - LOW_MEM) >> 12) 
#define USED 100

static long HIGH_MEM = 0;

// Memory map for memeory between 1MB and 16MB. Physical memory available can be
// less. Each byte in the map refers to the state of correponding physical page.
// 0 means free and 100 means used, value between 1 & 100 shows reference count.
static unsigned char mem_map[PAGING_PAGES] = {0};

// Init memory, mostly mem_map
void mem_init(long start_mem, long end_mem)
{
    HIGH_MEM = end_mem;     // Save physical address of memory end

    int i = 0;              // Set all pages 'USED'
    for (; i < PAGING_PAGES; i ++) {
        mem_map[i] = USED;
    }

    i = MAP_NR(start_mem);  // i = 768 = 3MB for buffer
    end_mem -= start_mem;
    end_mem >>= 12;         // nr phisical pages after buffer area

    while (end_mem-- > 0) { // Set pages after buffer (main memory area) unused
        mem_map[i++] = 0;
    }

    // TODO 1. We must first implememt and test Memory management before fork()
    void mem_test();
    mem_test();
}

// Get a free physical page by finding 0 byte in mem_mep[].
unsigned long get_free_page()
{
    unsigned long __res;

    // Find the byte in mem_map with value of 0 backwardly
    __asm__("std;"              // set direction flag. compare backwardly
    "repne; scasb;"             // compare al with edi
    "jne 1f;"
    "movb $1, 1(%%edi);"        // found, set page to 1
    "sall $12, %%ecx;"          // PAGING_PAGES >> 12
    "addl %2, %%ecx;"           // ecx --> physical page addr
    "movl %%ecx, %%edx;"     
    "movl $1024, %%ecx;"        // ecx = nr longs in page to be cleared
    "leal 4092(%%edx), %%edi;"  // edi --> page end, clear backwardly
    "rep; stosl;"               // clear with 0 in eax
    "movl %%edx, %%eax;"        // eax --> physical page addr
    "1:"
    :"=a"(__res)
    :"a"(0), "i"(LOW_MEM),"c"(PAGING_PAGES),
    "D"(mem_map + PAGING_PAGES - 1));

    return __res;
}

void free_page(unsigned long addr)
{
    if (addr < LOW_MEM) return;
    if (addr >= HIGH_MEM)
        panic("trying to free nonexistent page");
    addr -= LOW_MEM;
    addr >>= 12;
    if (mem_map[addr]--) return;
    
    panic("trying to free free page");
}


void mem_test()
{
    unsigned long idx1, idx2, idx3;
    idx1 = get_free_page();
    idx2 = get_free_page();
    idx3 = get_free_page();

    free_page(idx2);
    free_page(idx1);
    free_page(idx3);

    free_page(idx3);
}


