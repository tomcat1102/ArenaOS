SOURCES = $(wildcard kernel/*.c)
OBJ = $(SOURCES: .c = .o)

CC = /usr/local/i386elfgcc/bin/i386-elf-gcc
LD = /usr/local/i386elfgcc/bin/i386-elf-ld
GDB = /usr/local/i386elfgcc/bin/i386-elf-gdb

CFLAGS = -gcc

QEMU = qemu-system-i386

# final output system image
IMG = ArenaOS.img
# files for debug
DEBUG_FILES = boot_sector.elf boot_sector_init.elf
IMG_ELF = ArenaOS.img.elf

# default make target
$(IMG): boot/boot_sector.bin
	cat $^ > $@

# targets for debug files
boot_sector.elf: boot/boot_sector.o
	$(LD) -o $@ -melf_i386 -Ttext 0x0000 $^

boot_sector_init.elf: boot/boot_sector.o
	$(LD) -o $@ -melf_i386 -Ttext 0x7c00 $^

# general rules
%.bin:	%.asm
	nasm $< -f bin -o $@

%.o: %.asm
	nasm $< -f elf32 -F dwarf -g -o $@

# main targets
run: $(IMG)
	$(QEMU) -drive format=raw,file=$(IMG)

debug: $(IMG) $(DEBUG_FILES)
	$(QEMU) -s -S -drive format=raw,file=$(IMG) &
	$(GDB) -ex "target remote localhost:1234" \
	-ex "set architecture i8086" \
	-ex "set disassembly-flavor intel" \
	-ex "set confirm off" \
	-ex "symbol-file boot_sector_init.elf" \
	-ex "print _start" \
	-ex "break _start" \
	-ex "continue" \
	-ex "next 9" \
	-ex "symbol-file boot_sector.elf" \

	
clean:
	rm -rf $(IMG) $(IMG_ELF)
	rm -rf boot/*.bin boot/*.o
