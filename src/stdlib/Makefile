# Makefile for stdlib (stdlib/)
# Builds on Ubuntu using gcc -m32 + ar.

CC        = gcc
AR        = ar
DEL       = rm -f

BUILD     = ../build/
INCPATH   = ../build/haribote/

CFLAGS   = -m32 -ffreestanding -fno-pic -fno-pie -fno-stack-protector \
           -fno-builtin -fno-exceptions -nostdlib -nostdinc \
           -fno-asynchronous-unwind-tables -Wall -Wextra -O2 \
           -I$(INCPATH) -I../

default: stdlib.a

stdlib.a: stdlib.o Makefile
	$(AR) rcs $@ stdlib.o

%.o: %.c ../stdlib.h ../apilib.h Makefile
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	-$(DEL) *.o *.a

src_only:
	$(MAKE) clean
