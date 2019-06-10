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
KERNEL_OBJ = kernel/printk.o

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
$(INIT_OBJ): init
	@
$(KERNEL_OBJ): kernel
	@

# I quit, I don't know why bss cannot be allocated, nor can I control it.
# Now bss section won't appearing in the OS binary as strings of zeros,
# which is anyway pretty good. \(v.v)/
$(OS_BIN): $(INIT_OBJ) $(KERNEL_OBJ)
	$(LD) --script config/linker.ld -o $@ $^  --oformat binary

# Main make targets
run: $(IMG)
	$(QEMU) -m size=16 -mem-prealloc -drive format=raw,file=$(IMG)

debug: $(IMG) elf
	$(QEMU) -m size=16 -mem-prealloc -s -S -drive format=raw,file=$(IMG) & 
	$(GDB) --silent --command=config/gdb_commands.txt
	
clean:
	rm -rf ArenaOS.img os.bin os.elf core
	rm -rf boot/*.bin boot/*.o boot/*.elf boot/.depend
	rm -rf init/*.o init/*.elf
	rm -rf kernel/*.o kernel/*.elf

.PHONY: clean debug boot init kernel