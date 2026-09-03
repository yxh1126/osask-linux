/*
 * app.ld - Linker script template for Haribote OS applications (.hrb format)
 *
 * Same header format as kernel, but esp and mallocbase are parameterized.
 * The Makefile substitutes __STACK__ and __MALLOC__ via sed.
 *
 *   [0x00] segsiz    - 64KB fixed
 *   [0x04] "Hari"     - magic
 *   [0x08] 0          - reserved
 *   [0x0c] esp        - __STACK__ (initial ESP, data copy destination in data seg)
 *   [0x10] datsiz     - data size
 *   [0x14] dathrb     - data offset in file (LMA)
 *   [0x18] 0xE9000000 - JMP rel32
 *   [0x1c] rel32      - HariMain - 0x20
 *   [0x20] mallocbase - __MALLOC__
 *   [0x24] code starts
 *
 * Note: .text and .data live in DIFFERENT segments at runtime (code seg = file,
 * data seg = allocated buffer). The .data VMA only matters for linking; at
 * runtime only the LMA (dathrb = file offset of data) and esp (copy destination
 * in the data segment) are used. We place .data at a high VMA (0x10000000) so
 * it never overlaps .text in ld's address space, while the AT() directive
 * keeps the LMA contiguous after .text in the file.
 */

OUTPUT_FORMAT("binary")
ENTRY(HariMain)

SECTIONS
{
  .head 0x0 : {
    LONG(64 * 1024)              /* segsiz */
    LONG(0x69726148)             /* "Hari" */
    LONG(0)                       /* reserved */
    LONG(__STACK__)              /* esp - initial ESP, data copy dest in data seg */
    LONG(SIZEOF(.data))          /* datsiz */
    LONG(LOADADDR(.data))        /* dathrb - file offset of data (= .text end) */
    LONG(0xE9000000)             /* JMP rel32 at 0x1b */
    LONG(HariMain - 0x20)        /* rel32 offset */
    LONG(__MALLOC__)             /* mallocbase */
  }

  .text : {
    *(.text)
    *(.text.*)
  }

  /* Place .data at a high VMA to avoid overlap with .text. The AT() directive
     sets the LMA (load address = file offset) to be right after .text. */
  .data 0x10000000 : AT (ADDR(.text) + SIZEOF(.text)) {
    *(.data)
    *(.data.*)
    *(.rodata*)
    *(.bss)
    *(.bss.*)
    *(COMMON)
  }

  /DISCARD/ : {
    *(.eh_frame)
    *(.eh_frame_hdr)
    *(.comment)
    *(.note*)
    *(.debug*)
  }
}
