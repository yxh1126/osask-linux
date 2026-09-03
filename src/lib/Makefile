# Makefile for Haribote OS libraries (lib/)
# Builds apilib.a (nasm), stdlib.a (gcc -m32), and libc.o (freestanding C).
# These are consumed by the kernel (kernel/Makefile) and apps (app/app.mk)
# via the paths lib/apilib.a, lib/stdlib.a, and lib/libc.o.

NASM      = nasm
CC        = gcc
AR        = ar
DEL       = rm -f

INCPATH   = ../include/
NASMFLAGS = -f elf32
CFLAGS    = -m32 -ffreestanding -fno-pic -fno-pie -fno-stack-protector \
            -fno-builtin -fno-exceptions -nostdlib -nostdinc \
            -fno-asynchronous-unwind-tables -Wall -Wextra -O2 \
            -Wno-array-bounds -I$(INCPATH) -I../

# --- Default: build all three ---
default: apilib.a stdlib.a libc.o

# --- apilib.a: syscall wrappers (nasm) ---
apilib.a: apilib.o Makefile
	$(AR) rcs $@ apilib.o

# --- stdlib.a: printf/exit/malloc/free (C) ---
stdlib.a: stdlib.o Makefile
	$(AR) rcs $@ stdlib.o

# --- libc.o: freestanding C library (memset/vsprintf/etc.) ---
# Compiled separately (not archived) — linked directly into kernel and apps.
libc.o: libc.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

# --- Compile rules ---
%.o: %.nas Makefile
	$(NASM) $(NASMFLAGS) $< -o $@

%.o: %.c $(INCPATH)stdlib.h $(INCPATH)apilib.h Makefile
	$(CC) $(CFLAGS) -c $< -o $@

# --- Clean ---
clean:
	-$(DEL) *.o *.a *.lst

src_only:
	$(MAKE) clean
