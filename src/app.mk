# app.mk - Shared build template for Haribote OS applications
# Replaces app_make.txt. Each app Makefile sets APP, STACK, MALLOC and includes this file.
#
# Usage in app Makefile:
#   APP      = winhelo2
#   STACK    = 8k
#   MALLOC   = 0k
#   include ../app.mk
#
# Special variables (optional):
#   EXTRA_OBJS = extra .o files (e.g. bmp.o jpeg.o for gview)

# --- Tool paths ---
SRCPATH   := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ROOTPATH  := $(abspath $(SRCPATH))
BUILD     := $(SRCPATH)build/
HARIBOTE  := $(SRCPATH)haribote/
APILIB    := $(SRCPATH)apilib/
STDLIB    := $(SRCPATH)stdlib/
INCPATH   := $(SRCPATH)build/haribote/

# Make the .hrb the default goal when running `make -C <app_dir>`
.DEFAULT_GOAL := $(APP).hrb

# --- Tools ---
NASM      = nasm
CC        = gcc
LD        = ld
AR        = ar
OBJCOPY   = objcopy
COPY      = cp
DEL       = rm -f

# --- Flags ---
CFLAGS   = -m32 -ffreestanding -fno-pic -fno-pie -fno-stack-protector \
           -fno-builtin -fno-exceptions -nostdlib -Wall -Wextra -O2 \
           -Wno-array-bounds \
           -fno-asynchronous-unwind-tables -I$(INCPATH) -I../
# -Wno-array-bounds: gcc -O2 mis-reports fixed MMIO address casts
# (e.g. (int *)0x0fe4) as zero-size array accesses. These are legitimate
# bare-metal memory-mapped locations used by the OS and applications.
NASMFLAGS = -f elf32 -w-label-orphan
# -w-label-orphan: suppress label-without-colon warnings in legacy .nas files.

# --- Convert STACK/MALLOC (e.g. "8k") to hex addresses ---
# STACK is the .data VMA and initial ESP. The stack region sits above the
# code, so the hex value is the raw byte count of the stack size (e.g. 8k -> 0x2000).
STACK_DEC = $(shell echo $(STACK) | sed 's/k/*1024/' | bc)
MALLOC_DEC = $(shell echo $(MALLOC) | sed 's/k/*1024/' | bc)
STACK_HEX = 0x$(shell printf "%x" $(STACK_DEC))
MALLOC_HEX = 0x$(shell printf "%x" $(MALLOC_DEC))

# --- Link libraries (all apps need apilib + stdlib + libc) ---
# Link order: stdlib (printf/exit/malloc) calls apilib (api_*) and libc (vsprintf).
# Use --start-group to resolve circular dependencies.
LIB_DEPS = $(STDLIB)stdlib.a $(APILIB)apilib.a $(BUILD)libc.o
LIBS = --start-group $(LIB_DEPS) --end-group

# --- Per-app linker script generated from template ---
$(APP).ld: $(BUILD)app.ld
	sed -e 's/__STACK__/$(STACK_HEX)/' -e 's/__MALLOC__/$(MALLOC_HEX)/' $< > $@

# --- Default target ---
default: $(APP).hrb

# --- C compile rule ---
%.o: %.c ../apilib.h ../stdlib.h Makefile
	$(CC) $(CFLAGS) -c $< -o $@

# --- Assembly compile rule (for pure .nas apps like hello5) ---
%.o: %.nas Makefile
	$(NASM) $(NASMFLAGS) $< -o $@

# --- Link app .hrb ---
# EXTRA_OBJS (optional, e.g. bmp.o jpeg.o) are appended before libraries.
ifdef EXTRA_OBJS
$(APP).hrb: $(APP).o $(EXTRA_OBJS) $(APP).ld $(LIB_DEPS) Makefile
	$(LD) -m elf_i386 -T $(APP).ld -o $@ $(APP).o $(EXTRA_OBJS) $(LIBS)
else
$(APP).hrb: $(APP).o $(APP).ld $(LIB_DEPS) Makefile
	$(LD) -m elf_i386 -T $(APP).ld -o $@ $(APP).o $(LIBS)
endif

# --- Floppy image (single-app boot for testing) ---
haribote.img: $(HARIBOTE)ipl10.bin $(HARIBOTE)haribote.sys $(APP).hrb Makefile
	$(BUILD)mkimg.sh $@ $(HARIBOTE)ipl10.bin $(HARIBOTE)haribote.sys $(APP).hrb

# --- Commands ---
run: haribote.img
	qemu-system-i386 -drive file=haribote.img,format=raw,index=0,if=floppy \
		-display gtk

full:
	$(MAKE) -C $(APILIB)
	$(MAKE) -C $(STDLIB)
	$(MAKE) $(APP).hrb

run_full:
	$(MAKE) -C $(APILIB)
	$(MAKE) -C $(STDLIB)
	$(MAKE) -C $(HARIBOTE)
	$(MAKE) run

clean:
	-$(DEL) *.o *.ld *.hrb haribote.img

src_only:
	$(MAKE) clean
