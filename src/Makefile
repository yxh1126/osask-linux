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

APP_HRBS = a/a.hrb hello3/hello3.hrb hello4/hello4.hrb hello5/hello5.hrb \
           winhelo/winhelo.hrb winhelo2/winhelo2.hrb winhelo3/winhelo3.hrb \
           star1/star1.hrb stars/stars.hrb stars2/stars2.hrb \
           lines/lines.hrb walk/walk.hrb noodle/noodle.hrb \
           beepdown/beepdown.hrb color/color.hrb color2/color2.hrb \
           sosu/sosu.hrb sosu2/sosu2.hrb sosu3/sosu3.hrb \
           type/type.hrb iroha/iroha.hrb chklang/chklang.hrb \
           notrec/notrec.hrb bball/bball.hrb invader/invader.hrb \
           calc/calc.hrb tview/tview.hrb mmlplay/mmlplay.hrb gview/gview.hrb

# --- Data files copied onto the floppy image ---
DATA_FILES = euc.txt \
             mmldata/kirakira.mml mmldata/fujisan.mml \
             mmldata/daigo.mml mmldata/daiku.mml \
             pictdata/fujisan.jpg pictdata/night.bmp \
             nihongo/nihongo.fnt

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
	@for d in $(APPS); do $(MAKE) -C $$d clean || true; done
	-$(DEL) haribote.img

# --- 4. make qemu: boot the image in QEMU ---
qemu: img
	qemu-system-i386 -drive file=haribote.img,format=raw,index=0,if=floppy \
		-display gtk

.PHONY: default img clean qemu
