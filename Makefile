# Makefile for the whole os
CC = /usr/local/i386elfgcc/bin/i386-elf-gcc
LD = /usr/local/i386elfgcc/bin/i386-elf-ld
GDB = /usr/local/i386elfgcc/bin/i386-elf-gdb

QEMU = qemu-system-i386

INCLUDE = $(shell pwd)/include
CFLAGS = -std=c99 -Wall -g -I$(INCLUDE) -ffreestanding -Wno-unused-variable \
	-fno-asynchronous-unwind-tables -Wno-unused-but-set-variable \
	-fno-zero-initialized-in-bss

IMG = ArenaOS.img
BOOT_BIN = boot/boot_sector.bin boot/setup.bin
OS_BIN = os.bin

INIT_OBJ = init/head.o init/main.o 
KERNEL_OBJ = kernel/printk.o kernel/traps.o kernel/exceptions.o \
	kernel/mktime.o kernel/sched.o kernel/syscall.o kernel/fork.o \
	kernel/panic.o \
	kernel/chr_drv/keyboard.o kernel/chr_drv/tty_io.o kernel/chr_drv/console.o
MM_OBJ = mm/memory.o
LIB_OBJ = lib/errno.o	

OS_OBJ = $(INIT_OBJ) $(KERNEL_OBJ) $(MM_OBJ) $(LIB_OBJ)

# export variables to make in each directory
export CC
export LD
export CFLAGS
export INCLUDE

# default make target
all: $(IMG) 

boot:
	cd boot && make 

init:
	cd init && make

kernel:
	cd kernel && make
mm:
	cd mm && make
lib:
	cd lib && make

os.elf: $(OS_OBJ)
	cd boot && make debug
	$(LD) -o $@ --script config/linker.ld $^

$(IMG): $(BOOT_BIN) $(OS_BIN) kernel/fake_kernel
	cat $^ > $@
$(BOOT_BIN): boot
	@
$(INIT_OBJ): init
	@
$(KERNEL_OBJ): kernel
	@
$(MM_OBJ): mm
	@
$(LIB_OBJ):lib
	@

# I quit, I don't know why bss cannot be allocated, nor can I control it.
# Now bss section won't be appearing in the OS binary as strings of zeros,
# which is anyway pretty good. \(v.v)/

# Linking OS_BIN with lib objects is ok. They are pretty small.

$(OS_BIN): $(OS_OBJ)
	$(LD) --script config/linker.ld -o $@ $^  --oformat binary

# Main make targets
run: $(IMG)
	$(QEMU) -m size=16 -mem-prealloc -drive format=raw,file=$(IMG)

debug: $(IMG) os.elf
	$(QEMU) -m size=16 -mem-prealloc -s -S -realtime mlock=off -rtc base=localtime,clock=vm -drive format=raw,file=$(IMG) & 
	$(GDB) --silent --command=config/gdb_commands.txt
	
clean:
	rm -rf ArenaOS.img os.bin os.elf core
	rm -rf boot/*.bin boot/*.o boot/*.elf boot/.depend
	rm -rf init/*.o init/*.elf
	rm -rf kernel/*.o kernel/*.elf
	rm -rf kernel/chr_drv/*.o kernel/chr_drv/*.elf
	rm -rf mm/*.o mm/*.elf
	rm -rf lib/*.o lib/*.elf

# Lines of code in this repo
loc:
	git ls-files | /usr/bin/xargs wc -l

# display hex of os.img from 0x10000, skipping boot and setup sectors
xxd:
	xxd -s +1024 -o -1024 ArenaOS.img | more	

.PHONY: loc clean debug boot init kernel mm lib
