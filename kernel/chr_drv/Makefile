# Makefile for kernel/chr_drv
SRC = $(shell find *.c)
ASM = $(shell find *.asm)
OBJECTS = $(patsubst %.c, %.o, $(SRC)) $(patsubst %.asm, %.o, $(ASM)) 

all: $(OBJECTS) 

.depend: $(SRC)
	rm -f ./.depend
	$(CC) -I$(INCLUDE) -MM $^ > ./.depend

include .depend

keyboard.o: keyboard.asm
	nasm $< -f elf32 -F dwarf -g -o $@