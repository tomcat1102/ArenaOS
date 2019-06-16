# Makefile for kernel
SRC = $(shell find *.c)
ASM = $(shell find *.asm)
OBJECTS = $(patsubst %.c, %.o, $(SRC)) $(patsubst %.asm, %.o, $(ASM)) 

all: chr_drv_obj $(OBJECTS) 

chr_drv_obj:
	cd chr_drv && make

# Generate dependency file, so we don't have to specify them manually
.depend: $(SRC)
	rm -f ./.depend
	$(CC) -I$(INCLUDE) -MM $^ > ./.depend

include .depend


exceptions.o: exceptions.asm
	nasm $< -f elf32 -F dwarf -g -o $@

syscall.o: syscall.asm
	nasm $< -f elf32 -F dwarf -g -o $@