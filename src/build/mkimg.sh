#!/bin/bash
# mkimg.sh - Build Haribote OS floppy disk image
# Replaces edimg.exe + fdimg0at.tek
#
# Creates a 1474560-byte (1.44MB) FAT12 floppy image with:
#   - ipl10.bin as the boot sector (first 512 bytes)
#   - haribote.sys as the kernel
#   - application .hrb files
#   - data files (fonts, pictures, music, etc.)
#
# Usage: mkimg.sh <output.img> <ipl10.bin> <haribote.sys> [extra files...]
# Extra files are copied to the root directory of the image.

set -e

IMG="$1"
IPL10="$2"
HARIBOTE_SYS="$3"
shift 3
EXTRA_FILES=("$@")

# 1. Create empty 1.44MB image
truncate -s 1474560 "$IMG"

# 2. Format as FAT12 (creates BPB + FAT + root dir)
mkfs.fat -F 12 -n HARIBOTE "$IMG" >/dev/null 2>&1

# 3. Copy haribote.sys FIRST so it lands at the start of the FAT12 data area.
#    ipl10.bin loads raw sectors 2-360 to memory 0x8200 and JMPs to 0xc200, which
#    is where the first data-area sector maps (1 boot + 9 FAT + 9 FAT + 14 root
#    dir = 33 sectors; data starts at sector 34 = 0xc200 in memory). asmhead.nas
#    (the first 400 bytes of haribote.sys) must be at that address, so
#    HARIBOTE.SYS must be the first file in the data area.
mcopy -i "$IMG" "$HARIBOTE_SYS" ::HARIBOTE.SYS

# 4. Copy remaining files (apps, data) after haribote.sys
if [ ${#EXTRA_FILES[@]} -gt 0 ]; then
    for f in "${EXTRA_FILES[@]}"; do
        if [ -f "$f" ]; then
            mcopy -i "$IMG" "$f" ::
        fi
    done
fi

# 5. Write boot sector (ipl10.bin) over mkfs.fat's boot sector.
#    ipl10.bin is 512 bytes with its own valid FAT12 BPB (bytes/sector=512,
#    sec/cluster=1, reserved=1, 2 FATs, 224 root entries, 2880 total sectors,
#    0xf0 media, 9 sec/FAT) -- matching the geometry mkfs.fat created. ipl10's
#    boot code does not read BPB fields at runtime (it uses hardcoded values),
#    but the BPB must be consistent so BIOS and mtools agree on the layout.
#    We write the full 512-byte sector, preserving the FAT tables and root
#    directory that mkfs.fat + mcopy created in later sectors.
if [ ! -f "$IPL10" ]; then
    echo "Error: boot sector $IPL10 not found" >&2
    exit 1
fi

IPL10_SIZE=$(wc -c < "$IPL10")
if [ "$IPL10_SIZE" -ne 512 ]; then
    echo "Warning: ipl10.bin is $IPL10_SIZE bytes, expected 512" >&2
fi

# Overwrite only the first 512 bytes (boot sector) with ipl10.bin.
# FAT tables, root directory, and file data remain intact.
dd if="$IPL10" of="$IMG" bs=512 count=1 conv=notrunc 2>/dev/null

# Ensure boot signature 0x55 0xAA at offset 0x1FE
printf '\x55\xaa' | dd of="$IMG" bs=1 seek=510 conv=notrunc 2>/dev/null

echo "mkimg: created $IMG ($(wc -c < "$IMG") bytes)"
