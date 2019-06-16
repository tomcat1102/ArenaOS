# Makefile for lib
SRC = $(shell find *.c)
OBJECTS = $(patsubst %.c, %.o, $(SRC)) 

all: $(OBJECTS) 

.depend: $(SRC)
	rm -f ./.depend
	$(CC) -I$(INCLUDE) -MM $^ > ./.depend

include .depend
