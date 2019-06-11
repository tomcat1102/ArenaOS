SRC = $(shell find *.c)
OBJECTS = $(patsubst %.c, %.o, $(SRC)) exceptions.o

all: $(OBJECTS)

# Generate dependency file, so we don't have to specify them manually
.depend: $(SRC)
	rm -f ./.depend
	$(CC) -I$(INCLUDE) -MM $^ > ./.depend

include .depend

exceptions.o: exceptions.asm
	nasm $< -f elf32 -F dwarf -g -o $@
