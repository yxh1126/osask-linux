# Makefile for Haribote OS libraries (lib/)
# Builds apilib.a (nasm) and stdlib.a (gcc -m32) in one place.
# Both archives are consumed by the kernel (kernel/Makefile) and apps
# (app/app.mk) via the paths lib/apilib.a and lib/stdlib.a.

NASM      = nasm
CC        = gcc
AR        = ar
DEL       = rm -f

INCPATH   = ../include/
NASMFLAGS = -f elf32
CFLAGS    = -m32 -ffreestanding -fno-pic -fno-pie -fno-stack-protector \
            -fno-builtin -fno-exceptions -nostdlib -nostdinc \
            -fno-asynchronous-unwind-tables -Wall -Wextra -O2 \
            -I$(INCPATH) -I../

# --- Default: build both archives ---
default: apilib.a stdlib.a

# --- apilib.a: syscall wrappers (nasm) ---
apilib.a: apilib.o Makefile
	$(AR) rcs $@ apilib.o

# --- stdlib.a: printf/exit/malloc/free (C) ---
stdlib.a: stdlib.o Makefile
	$(AR) rcs $@ stdlib.o

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
