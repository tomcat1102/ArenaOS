#ifndef UNISTD_H
#define UNISTD_H

/*
*   Unistd.h 6.16. 
*   Contains system call declarations and vairous constants
*/

// Contents in __LIBRARY__ are used by kernel to implement system call library 
// and invocation with assembly. System call lib is generatedy from files in 
// lib directory wiht name 'libc.o'. Some files in lib contains additional 
// processing such as setting errno and some sanity checks.
//
// User programs shouldn't define __LIBRAY__ to invoke system call directly and 
// are suggested to use correponding syscall funcition declarations and then be
// linked against the generated libc.o.

#define __LIBRARY__

#ifdef __LIBRARY__

#define __NR_setup       0
#define __NR_exit        1
#define __NR_fork        2
#define __NR_read        3

// Inline assembly for invoking system call with specified call name & ret type.
#define __syscall0(type, name) \
type name(void) { \
    long __res; \
    __asm__ volatile("int $0x80" \
    :"=a"(__res) \
    :"a"(__NR_ ## name)); \
    if (__res >= 0) \
        return (type) __res; \
    errno = -__res; \
    return -1; \
}

#endif // __LIBRARY__


extern int errno;


#endif // UNISTD_H