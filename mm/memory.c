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

// Refresh TLB by setting cr3 to itself
#define invalidate() \
__asm__("movl %%eax, %%cr3"::"a"(0))

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

// Free the physical page at addr by resetting corrosponding byte in mem_map[]
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


// Copy linear memory address space spanned by page directory entries in units
// of 4MB from source to destination. Note when from = 0, we are copying kernel 
// space for the first fork(). We don't copy 4MB linear space instead, we copy 
// just first 640KB (That's still large than current kernel size). And we don't
// allow Copy-on-write in kernel space (the first 1MB) and let task 0 & 1 share
// the kernel pages.
int copy_page_tables(unsigned long from, unsigned long to, unsigned long size)
{
    if ((from & 0x3fffff) || (to & 0x3fffff))
        panic("copy_paga_tables called with wrong alignment");
    
    // Understood :)
    unsigned long *from_dir = (unsigned long *)((from >> 20) & 0xffc); 
    unsigned long *to_dir   = (unsigned long *)((to >> 20) & 0xffc);
    size = (size + 0x3fffff) >> 22;

    unsigned long *from_page_table;
    unsigned long *to_page_table;
    unsigned long nr;
    unsigned long this_page;

    // Copy page direcoty entris one by one
    for(; size-- > 0; from_dir ++, to_dir ++) {
        if (1 & *to_dir)        // Page can't exist in child task                
            panic("copy_page_tables: page already exists");
        if (! (1 & *from_dir))  // Page not exits ok in parent task, skip copy
            continue;   

        from_page_table = (unsigned long *)(0xfffff000 & *from_dir);
        if(! (to_page_table = (unsigned long *)get_free_page()))
            panic("copy_page_tables: OOM");
        // Set target page directory entry
        *to_dir = ((unsigned long)to_page_table | 7); // present, r/w, user page
        nr = (from == 0) ? 0xA0 : 1024; // Copy 160 page table entries if from 0
        for(; nr-- > 0; from_page_table ++, to_page_table ++) {
            this_page = *from_page_table;
            if (! (1 & this_page))  // page table entry not exist, ok, skip copy
                continue;
            this_page &= ~2; // Read only page for child. Always do so.
            *to_page_table = this_page;
            // Is this page from user process space, not kernel ?
            if (this_page > LOW_MEM) {
                // Read only page for parent.
                // Now COW ok! Either child or parent process's write cause COW
                *from_page_table = this_page; 
                // Increase page reference count in mem_map[]
                this_page -= LOW_MEM;
                this_page >>= 12;
                mem_map[this_page] ++;
            }
        }
    }
    invalidate();
    return 0;
}


