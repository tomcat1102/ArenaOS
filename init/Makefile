SRC = $(shell find *.c)
OBJECTS = $(patsubst %.c, %.o, $(SRC)) head.o

all: $(OBJECTS) head.o

head.o: head.asm
	nasm $< -f elf32 -F dwarf -g -o $@

# Generate dependency file, so we don't have to specify them manually
# Must be placed after default rules
.depend: $(SRC)
	rm -f ./.depend
	$(CC) -I$(INCLUDE) -MM $^ > ./.depend

include .depend