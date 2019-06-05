CC = /usr/local/i386elfgcc/bin/i386-elf-gcc
LD = /usr/local/i386elfgcc/bin/i386-elf-ld
GDB = /usr/local/i386elfgcc/bin/i386-elf-gdb

QEMU = qemu-system-i386

INCLUDE = $(shell pwd)/include
CFLAGS = -Wall -g -I$(INCLUDE) -ffreestanding -Wno-unused-variable

IMG = ArenaOS.img
BOOT_BIN = boot/boot_sector.bin boot/setup.bin
OS_BIN = os.bin

INIT_OBJ = init/head.o init/main.o 
KERNEL_OBJ = kernel/print.o

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

elf: 
	cd boot && make debug
	$(LD) -o os.elf -Ttext=0x0000 $(INIT_OBJ) $(KERNEL_OBJ)

$(IMG): $(BOOT_BIN) $(OS_BIN) kernel/fake_kernel
	cat $^ > $@
$(BOOT_BIN): boot
	@
$(OS_BIN): $(INIT_OBJ) $(KERNEL_OBJ)
	$(LD) -o $@ $^ --oformat binary --entry startup_32
$(INIT_OBJ): init
	@
$(KERNEL_OBJ): kernel
	@

# Main make targets
run: $(IMG)
	$(QEMU) -m size=16 -mem-prealloc -drive format=raw,file=$(IMG)

debug: $(IMG) elf
	$(QEMU) -m size=16 -mem-prealloc -s -S -drive format=raw,file=$(IMG) & 
	$(GDB) --silent --command=debug/gdb_commands
	
clean:
	rm -rf ArenaOS.img os.bin os.elf
	rm -rf boot/*.bin boot/*.o boot/*.elf boot/.depend
	rm -rf init/*.o init/*.elf
	rm -rf kernel/*.o kernel/*.elf

.PHONY: clean debug boot init kernel