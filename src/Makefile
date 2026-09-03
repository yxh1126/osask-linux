# Top-level Makefile for Haribote OS (src/)
# Builds on Ubuntu using nasm + gcc -m32 + ld + mtools.
#
# Targets:
#   make        -- build all source code (kernel, libs, apps)
#   make img    -- generate the final boot floppy image (haribote.img)
#   make clean  -- remove all build files and the image
#   make qemu   -- boot the image in QEMU

BUILD     = build/
DEL       = rm -f

# --- App directories (each has its own Makefile including ../app.mk) ---
APPS = a hello3 hello4 hello5 winhelo winhelo2 winhelo3 \
       star1 stars stars2 lines walk noodle \
       beepdown color color2 sosu sosu2 sosu3 \
       type iroha chklang notrec bball invader \
       calc tview mmlplay gview

APP_HRBS = app/a/a.hrb app/hello3/hello3.hrb app/hello4/hello4.hrb app/hello5/hello5.hrb \
           app/winhelo/winhelo.hrb app/winhelo2/winhelo2.hrb app/winhelo3/winhelo3.hrb \
           app/star1/star1.hrb app/stars/stars.hrb app/stars2/stars2.hrb \
           app/lines/lines.hrb app/walk/walk.hrb app/noodle/noodle.hrb \
           app/beepdown/beepdown.hrb app/color/color.hrb app/color2/color2.hrb \
           app/sosu/sosu.hrb app/sosu2/sosu2.hrb app/sosu3/sosu3.hrb \
           app/type/type.hrb app/iroha/iroha.hrb app/chklang/chklang.hrb \
           app/notrec/notrec.hrb app/bball/bball.hrb app/invader/invader.hrb \
           app/calc/calc.hrb app/tview/tview.hrb app/mmlplay/mmlplay.hrb app/gview/gview.hrb

# --- Data files copied onto the floppy image ---
DATA_FILES = app/data/textdata/euc.txt \
             app/data/mmldata/kirakira.mml app/data/mmldata/fujisan.mml \
             app/data/mmldata/daigo.mml app/data/mmldata/daiku.mml \
             app/data/pictdata/fujisan.jpg app/data/pictdata/night.bmp \
             app/data/nihongo/nihongo.fnt

# --- 1. make: build all source code (kernel, libraries, apps) ---
default: kernel/ipl10.bin kernel/haribote.sys \
         lib/apilib.a lib/stdlib.a lib/libc.o $(APP_HRBS)

kernel/ipl10.bin kernel/haribote.sys:
	$(MAKE) -C kernel

lib/apilib.a lib/stdlib.a lib/libc.o:
	$(MAKE) -C lib

$(APP_HRBS): lib/apilib.a lib/stdlib.a lib/libc.o kernel/haribote.sys
	@dir=$(dir $@); $(MAKE) -C $$dir

# --- 2. make img: generate the final boot floppy image ---
img: haribote.img

haribote.img: default $(DATA_FILES) Makefile build/mkimg.sh
	$(BUILD)mkimg.sh $@ kernel/ipl10.bin kernel/haribote.sys \
		$(APP_HRBS) $(DATA_FILES)

# --- 3. make clean: remove all build files and image ---
clean:
	$(MAKE) -C kernel clean
	$(MAKE) -C lib clean
	@for d in $(APPS); do $(MAKE) -C app/$$d clean || true; done
	-$(DEL) haribote.img

# --- 4. make qemu: boot the image in QEMU ---
qemu: img
	qemu-system-i386 -drive file=haribote.img,format=raw,index=0,if=floppy \
		-display gtk

.PHONY: default img clean qemu
