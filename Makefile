SOURCES = $(wildcard kernel/*.c)
OBJ = $(SOURCES: .c = .o)

CC = /usr/local/i386elfgcc/bin/i386-elf-gcc
LD = /usr/local/i386elfgcc/bin/i386-elf-ld
GDB = /usr/local/i386elfgcc/bin/i386-elf-gdb

CFLAGS = -gcc

QEMU = qemu-system-i386

# final output system image
IMG = ArenaOS.img
# image for debugmake
IMG_ELF = ArenaOS.img.elf

# default make target
$(IMG): boot/boot_sector.bin
	cat $^ > $@

$(IMG_ELF): boot/boot_sector.o
	$(LD) -o $@ -Ttext 0x07c00 $^

%.bin:	%.asm
	nasm $< -f bin -o $@

%.o: %.asm
	nasm $< -f elf -F dwarf -g -o $@

run: $(IMG)
	$(QEMU) -drive format=raw,file=$(IMG)

debug: $(IMG) $(IMG_ELF)
	$(QEMU) -s -S -drive format=raw,file=$(IMG) &
	$(GDB) -ex "target remote localhost:1234" -ex "symbol-file $(IMG_ELF)"

clean:
	rm -rf $(IMG) $(IMG_ELF)
	rm -rf boot/*.bin boot/*.o
