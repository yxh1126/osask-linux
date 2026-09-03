# Makefile for Haribote OS kernel (haribote/)
# Builds on Ubuntu using nasm + gcc -m32 + ld.

# --- Tools ---
NASM      = nasm
CC        = gcc
LD        = ld
OBJCOPY   = objcopy
COPY      = cp
DEL       = rm -f

BUILD     = ../build/
INCPATH   = ../build/haribote/

# --- Flags ---
CFLAGS   = -m32 -ffreestanding -fno-pic -fno-pie -fno-stack-protector \
           -fno-builtin -fno-exceptions -nostdlib -nostdinc \
           -fno-asynchronous-unwind-tables -Wall -Wextra -O2 \
           -Wno-array-bounds \
           -I$(INCPATH) -I../
# -Wno-array-bounds: gcc -O2 mis-reports fixed MMIO address casts
# (e.g. (struct BOOTINFO *)0x0ff0, (int *)0x0fe4) as zero-size array
# accesses. These are legitimate bare-metal memory-mapped locations.
NASMFLAGS_ELF = -f elf32
NASMFLAGS_BIN = -f bin -w-zeroing
# -w-zeroing: suppress "uninitialized space in .text" for RESB in boot
# sector and GDT alignment — these are intentional zero-fill placeholders.

# --- Kernel object files ---
OBJS_BOOTPACK = bootpack.o naskfunc.o hankaku.o graphic.o dsctbl.o \
               int.o fifo.o keyboard.o mouse.o memory.o sheet.o timer.o \
               mtask.o window.o console.o file.o tek.o

# --- Default ---
default: ipl10.bin haribote.sys

# --- Boot sector (flat binary) ---
ipl10.bin: ipl10.nas Makefile
	$(NASM) $(NASMFLAGS_BIN) ipl10.nas -o ipl10.bin

# --- asmhead (flat binary, part of haribote.sys) ---
asmhead.bin: asmhead.nas Makefile
	$(NASM) $(NASMFLAGS_BIN) asmhead.nas -o asmHead.bin
	mv asmHead.bin asmhead.bin

# --- Font data ---
hankaku.bin: hankaku.txt $(BUILD)makefont.py
	python3 $(BUILD)makefont.py hankaku.txt hankaku.bin

hankaku.o: hankaku.bin Makefile
	$(OBJCOPY) -I binary -O elf32-i386 -B i386 \
		--redefine-sym _binary_hankaku_bin_start=hankaku \
		--redefine-sym _binary_hankaku_bin_end=hankaku_end \
		--redefine-sym _binary_hankaku_bin_size=hankaku_size \
		hankaku.bin hankaku.o

# --- Assembly (.nas -> .o, ELF) ---
%.o: %.nas Makefile
	$(NASM) $(NASMFLAGS_ELF) $< -o $@

# --- C source (.c -> .o) ---
%.o: %.c bootpack.h Makefile
	$(CC) $(CFLAGS) -c $< -o $@

# --- Link kernel -> bootpack.hrb ---
bootpack.hrb: $(OBJS_BOOTPACK) $(BUILD)hrb.ld $(BUILD)libc.o Makefile
	$(LD) -m elf_i386 -T $(BUILD)hrb.ld -o $@ \
		$(OBJS_BOOTPACK) $(BUILD)libc.o

# --- System image ---
haribote.sys: asmhead.bin bootpack.hrb Makefile
	cat asmhead.bin bootpack.hrb > haribote.sys

# --- Clean ---
clean:
	-$(DEL) *.o *.bin *.hrb *.sys *.lst *.map

src_only:
	$(MAKE) clean
	-$(DEL) ipl10.bin haribote.sys
