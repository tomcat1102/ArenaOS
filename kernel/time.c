#include <asm/port_io.h>

#define RTC_SECONDS         0
#define RTC_MINUTES         2
#define RTC_HOURS           4
#define RTC_DAY_OF_WEEK     6
#define RTC_DAY_OF_MONTH    7
#define RTC_MONTH           8
#define RTC_YEAR            9

#define RTC_REG_A           10
#define RTC_REG_B           11

// Read information from CMOS at specified address of RTC_XXX.
#define CMOS_READ(addr) ({\
    outb(addr, 0x70);\
    inb(0x71);\
})
// Convert data from BCD (Bianry coded decimal) format to binary format.
#define BCD_TO_BIN(val) (\
    (val) = ((val) & 0x0f) + ((val) >> 4) * 10)

#define MINUTE  60
#define HOUR    (60 * MINUTE)
#define DAY     (24 * HOUR)
#define YEAR    (365 * DAY)

static int month[12] = {
    0,
    DAY * (31),
    DAY * (31 + 29),
    DAY * (31 + 29 + 31),
    DAY * (31 + 29 + 31 + 30),
    DAY * (31 + 29 + 31 + 30 + 31),
    DAY * (31 + 29 + 31 + 30 + 31 + 30),
    DAY * (31 + 29 + 31 + 30 + 31 + 30 + 31),
    DAY * (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31),
    DAY * (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30),
    DAY * (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31),
    DAY * (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30)
};

extern long startup_time;       // defined and used in sched.c

// See https://wiki.osdev.org/CMOS for more info
void time_init(void)
{
    unsigned char sec;   // 0 - 59
    unsigned char min;   // 0 - 59
    unsigned char hour;  // 0 - 23 or 1 - 12
    unsigned char wday;  // 1 - 7, Sunday = 1
    unsigned char mday;  // 1 - 31
    unsigned char mon;   // 1 - 12
    unsigned char year;  // 1 - 99

    do {
        sec  = CMOS_READ(RTC_SECONDS);
        min  = CMOS_READ(RTC_MINUTES);
        hour = CMOS_READ(RTC_HOURS);
        wday = CMOS_READ(RTC_DAY_OF_WEEK);
        mday = CMOS_READ(RTC_DAY_OF_MONTH);
        mon  = CMOS_READ(RTC_MONTH);
        year = CMOS_READ(RTC_YEAR);
    } while (sec != CMOS_READ(0x00));  // second-level accuracy

    unsigned char status = CMOS_READ(RTC_REG_B);
    if (!(status & 0x04)) {        // need to convert BCD to binary
        BCD_TO_BIN(sec);
        BCD_TO_BIN(min);
        BCD_TO_BIN(hour);
        BCD_TO_BIN(wday);
        BCD_TO_BIN(mday);
        BCD_TO_BIN(mon);
        BCD_TO_BIN(year);
    }

    year += 30; // Year seems like from 2000, not 1970, so add 30 more years
    mon --;     // change from [1 - 12] to [0 - 11]

    unsigned long res = YEAR * year + DAY * ((year + 1) / 4);
    res += month[mon];
    if (mon > 1 && ((year + 2) % 4))
        res -= DAY;
    res += DAY * (mday - 1);
    res += HOUR * hour;
    res += MINUTE * min;
    res += sec;

    startup_time = res;     // set startup_time for sched.c
}

