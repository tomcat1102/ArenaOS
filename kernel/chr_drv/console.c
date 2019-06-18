/*
*   console.c 6.12    console device
*/

#include <asm/system.h>
#include <asm/port_io.h>
#include <tty.h>
#include <common.h>

// helper defines to retrieve info at 0x90000. See setup.asm
#define ORIG_X              (*(unsigned char*)0x90000)
#define ORIG_Y              (*(unsigned char*)0x90001)
#define ORIG_VIDEO_MODE     ((*(unsigned short*)0x90006) & 0xff)
#define ORIG_VIDEO_COLS     (((*(unsigned short*)0x90006) & 0xff00) >> 8)
#define ORIG_VIDEO_LINES    (25)
#define ORIG_VIDEO_EGA_AX   (*(unsigned short*)0x90008)
#define ORIG_VIDEO_EGA_BX   (*(unsigned short*)0x9000a)
#define ORIG_VIDEO_EGA_CX   (*(unsigned short*)0x9000c)

// Video types:   MDA->CGA->EGA->VGA
#define VIDEO_TYPE_MDA      0x10    // Monochrome text display
#define VIDEO_TYPE_CGA      0x11    // CGA display
#define VIDEO_TYPE_EGAM     0x20    // EGA/VGA in monochrome mode
#define VIDEO_TYPE_EGAC     0x21    // EGA/VGA in color mode

extern void keyboard_interrupt(void);

// constants
static unsigned long video_type;            // display type. CGA, VGA ...
static unsigned long video_num_columns;     // number of text columns in screen
static unsigned long video_num_lines;       // number of text lines in screen
static unsigned long video_mem_start;       // start address of video memory
static unsigned long video_mem_end;         // end address of video memory   
static unsigned long video_port_reg;        // video register select port
static unsigned long video_port_val;        // video register value port
static unsigned long video_size_row;        // video_num_columns * 2

// vairables (for scrolling)
static unsigned long x,y;                   // x & y coord in 80x25
static unsigned long top, bottom;           // top and bottom line number
static unsigned long ori, end;              // video mem range to display
static unsigned long pos;                   // cur pos from 0 in [ori, end]

// Update x, y and pos in 80x25 to new x and y. Note x = cols and y = rows
static inline void gotoxy(unsigned int new_x, unsigned new_y)
{
    if (new_x > video_num_columns || new_y >= video_num_lines){
        panic("gotoxy: bad x or y");
    }

    x = new_x;
    y = new_y;
    pos = ori + y * video_size_row + (x << 1);

}

// TODO test code for timer and task switching
// print A if task 0 is running at timer interrupt, or B if task 1
#include <sched.h>
void timer_print()
{
    if (current->pid == 0) {
        *(char*)pos = 'A';
        pos ++;
        *(char*)pos = 4;
        pos ++;
    } else if (current->pid == 1) {
        *(char*)pos = 'B';
        pos ++;
        *(char*)pos = 2;
        pos ++;
    } else {
        *(char*)pos = 'C';
        pos ++;
        *(char*)pos = 7;
        pos ++;
    }
}

void con_init(void)
{
    char *display_desc = "????";
    char *display_ptr;

    video_num_columns = ORIG_VIDEO_COLS;
    video_num_lines = ORIG_VIDEO_LINES;     // currently it's 80x25
    video_size_row = video_num_columns * 2;

    if (ORIG_VIDEO_MODE == 7) {             // monochrome display? no support
        panic("con_init: mono display not supported");
    } else {                                // color display
        video_mem_start = 0xb8000;          // 640KB + 96KB
        video_port_reg = 0x3d4;
        video_port_val = 0x3d5;
        if ((ORIG_VIDEO_EGA_BX & 0xff) != 0x10) {
            video_type = VIDEO_TYPE_EGAC;
            video_mem_end = 0xbc000;        // 640KB + 112KB,thus video ram 16KB
            display_desc = "EGAc";
        } else {
            video_type = VIDEO_TYPE_CGA;
            video_mem_end = 0xba000;        // 640KB + 104KB, thus video raw 8KB
            display_desc = "*CGA";
        }
    }

    // Print display description at top-right corner. currently EGAc is printed.
    display_ptr = (char*)video_mem_start + video_size_row - 8;

    while (*display_desc) {
        *display_ptr ++ = *display_desc ++;
        display_ptr ++; // skip mode byte
    }

    // Init vars for scrolling
    ori = video_mem_start;
    end = video_mem_start + video_num_lines * video_size_row;
    top = 0;
    bottom = video_num_lines;
    gotoxy(ORIG_X, ORIG_Y + 1);

    // Set keyboard interrupt handler and unmask its signal
    set_trap_gate(0x21, keyboard_interrupt);
    outb(inb(0x21) & 0xfd, 0x21);
    
    // Enable keyboard by first disabling it and then enabling it again.
    unsigned char val = inb(0x61);
    outb(val | 0x80, 0x61);
    outb(val, 0x61);
}