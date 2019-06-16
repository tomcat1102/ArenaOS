/*
*   Panic.c 6.16
*   Used throughout the kernel to indicate a fatal kernel error
*/

void panic(const char *s)
{
    // Note after implemeting console screen, we should print the error
    // message before looping forever.
    while(1);
}