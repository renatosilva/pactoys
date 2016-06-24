# Simple makefile to build inih as a static library

SOURCE = ini.c
OBJECT = $(SOURCE:.c=.o)
OUTPUT = libinih.a
INCLUDES = -I.
CCFLAGS = -g -O2
CC = gcc

default: $(OUTPUT)

.c.o:
	$(CC) $(INCLUDES) $(CCFLAGS) $(EXTRACCFLAGS) -c $< -o $@

$(OUTPUT): $(OBJECT)
	ar rcs $(OUTPUT) $(OBJECT) $(EXTRAARFLAGS)

clean:
	rm -f $(OBJECT) $(OUTPUT)
