/*
 * hrb.ld - Linker script for the Haribote OS kernel (bootpack.hrb)
 *
 * Produces a flat binary .hrb file with a 36-byte header.
 *
 *   [0x00] segsiz    - 64KB (kernel segment size)
 *   [0x04] "Hari"     - magic 0x69726148
 *   [0x08] 0          - reserved
 *   [0x0c] esp        - 0x310000 (kernel data VMA)
 *   [0x10] datsiz     - SIZEOF(.data)
 *   [0x14] dathrb     - LOADADDR(.data) (file offset of data)
 *   [0x18] 0xE9000000 - JMP rel32 opcode at byte 0x1b
 *   [0x1c] rel32      - HariMain - 0x20
 *   [0x20] mallocbase - 0 (kernel doesn't use api008 malloc)
 *   [0x24] code section starts
 *
 * The kernel is loaded at 0x280000 by asmhead.nas.
 * GDT entry 2: base=0x280000, so code at 0x280000+0x24.
 * Data segment at 0x280000+0x310000.
 */

OUTPUT_FORMAT("binary")
ENTRY(HariMain)

SECTIONS
{
  .head 0x0 : {
    LONG(64 * 1024)              /* segsiz */
    LONG(0x69726148)             /* "Hari" */
    LONG(0)                       /* reserved */
    LONG(0x310000)               /* esp (data VMA) */
    LONG(SIZEOF(.data))          /* datsiz */
    LONG(LOADADDR(.data))        /* dathrb */
    LONG(0xE9000000)             /* JMP rel32 at 0x1b */
    LONG(HariMain - 0x20)        /* rel32 offset */
    LONG(0)                       /* mallocbase */
  }

  .text : {
    *(.text)
    *(.text.*)
  }

  .data 0x310000 : AT (ADDR(.text) + SIZEOF(.text)) {
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
