/*
*   printk.c  6.10
*/

// print function used in kernel mode
// however now it's juct a dummy function cause tty is not implemented
// and there is nowhere to print the formated strings.


int printk() {
    int a = 0xDEADBEEF;
    return a;
}