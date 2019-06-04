SRC = $(shell find *.c)
OBJECTS = $(patsubst %.c, %.o, $(SRC))

# Generate dependency file, so we don't have to specify them manually
.depend: $(SRC)
	rm -f ./.depend
	$(CC) -I$(INCLUDE) -MM $^ > ./.depend

include .depend

all: $(OBJECTS)
