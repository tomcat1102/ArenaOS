# Makefile for mm
SRC = $(shell find *.c)
ASM = $(shell find *.asm)
OBJECTS = $(patsubst %.c, %.o, $(SRC)) $(patsubst %.asm, %.o, $(ASM)) 

all: $(OBJECTS) 

.depend: $(SRC)
	rm -f ./.depend
	$(CC) -I$(INCLUDE) -MM $^ > ./.depend

include .depend
