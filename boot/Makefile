.default: all

all: boot_sector.bin setup.bin head.bin fake_kernel.bin
# targets for buiding kernel
boot_sector.bin: boot_sector.asm print.asm
	nasm $< -f bin -o $@

setup.bin: setup.asm print.asm
	nasm $< -f bin -o $@

head.bin: head.asm print.asm
	nasm $< -f bin -o $@


# targets for debug
debug:	boot_sector.elf boot_sector_init.elf setup.elf head.elf fake_kernel.bin


fake_kernel.bin: fake_kernel.asm
	nasm $< -f bin -o $@

boot_sector.o: boot_sector.asm print.asm
	nasm $< -f elf32 -F dwarf -g -o $@

setup.o: setup.asm print.asm
	nasm $< -f elf32 -F dwarf -g -o $@

head.o: head.asm print.asm
	nasm $< -f elf32 -F dwarf -g -o $@

boot_sector.elf: boot_sector.o
	$(LD) -o $@ -melf_i386 -Ttext 0x0000 $^

boot_sector_init.elf: boot_sector.o
	$(LD) -o $@ -melf_i386 -Ttext 0x7c00 $^	

setup.elf: setup.o
	$(LD) -o $@ -melf_i386 -Ttext 0x0000 $^

head.elf: head.o
	$(LD) -o $@ -melf_i386 -Ttext 0x0000 $^


