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

# --- App directories (each has its own Makefile including ../../app.mk) ---
APPS = a hello3 hello4 hello5 winhelo winhelo2 winhelo3 \
       star1 stars stars2 lines walk noodle \
       beepdown color color2 sosu sosu2 sosu3 \
       type iroha chklang notrec bball invader \
       calc tview mmlplay gview

APP_HRBS = app_src/a/a.hrb app_src/hello3/hello3.hrb app_src/hello4/hello4.hrb app_src/hello5/hello5.hrb \
           app_src/winhelo/winhelo.hrb app_src/winhelo2/winhelo2.hrb app_src/winhelo3/winhelo3.hrb \
           app_src/star1/star1.hrb app_src/stars/stars.hrb app_src/stars2/stars2.hrb \
           app_src/lines/lines.hrb app_src/walk/walk.hrb app_src/noodle/noodle.hrb \
           app_src/beepdown/beepdown.hrb app_src/color/color.hrb app_src/color2/color2.hrb \
           app_src/sosu/sosu.hrb app_src/sosu2/sosu2.hrb app_src/sosu3/sosu3.hrb \
           app_src/type/type.hrb app_src/iroha/iroha.hrb app_src/chklang/chklang.hrb \
           app_src/notrec/notrec.hrb app_src/bball/bball.hrb app_src/invader/invader.hrb \
           app_src/calc/calc.hrb app_src/tview/tview.hrb app_src/mmlplay/mmlplay.hrb app_src/gview/gview.hrb

# --- Data files copied onto the floppy image ---
DATA_FILES = app_data/textdata/euc.txt \
             app_data/mmldata/kirakira.mml app_data/mmldata/fujisan.mml \
             app_data/mmldata/daigo.mml app_data/mmldata/daiku.mml \
             app_data/pictdata/fujisan.jpg app_data/pictdata/night.bmp \
             app_data/nihongo/nihongo.fnt

# --- 1. make: build all source code (kernel, libraries, apps) ---
default: haribote/ipl10.bin haribote/haribote.sys \
         apilib/apilib.a stdlib/stdlib.a $(APP_HRBS)

haribote/ipl10.bin haribote/haribote.sys:
	$(MAKE) -C haribote

apilib/apilib.a:
	$(MAKE) -C apilib

stdlib/stdlib.a:
	$(MAKE) -C stdlib

$(APP_HRBS): apilib/apilib.a stdlib/stdlib.a haribote/haribote.sys
	@dir=$(dir $@); $(MAKE) -C $$dir

# --- 2. make img: generate the final boot floppy image ---
img: haribote.img

haribote.img: default $(DATA_FILES) Makefile build/mkimg.sh
	$(BUILD)mkimg.sh $@ haribote/ipl10.bin haribote/haribote.sys \
		$(APP_HRBS) $(DATA_FILES)

# --- 3. make clean: remove all build files and image ---
clean:
	$(MAKE) -C haribote clean
	$(MAKE) -C apilib clean
	$(MAKE) -C stdlib clean
	@for d in $(APPS); do $(MAKE) -C app_src/$$d clean || true; done
	-$(DEL) haribote.img

# --- 4. make qemu: boot the image in QEMU ---
qemu: img
	qemu-system-i386 -drive file=haribote.img,format=raw,index=0,if=floppy \
		-display gtk

.PHONY: default img clean qemu
