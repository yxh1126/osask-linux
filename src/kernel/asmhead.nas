; haribote-os boot asm
; TAB=4


VBEMODE	EQU		0x105			; 1024 x 768 x 8bit color
; Display modes
;	0x100 :  640 x  400 x 8bit color
;	0x101 :  640 x  480 x 8bit color
;	0x103 :  800 x  600 x 8bit color
;	0x105 : 1024 x  768 x 8bit color
;	0x107 : 1280 x 1024 x 8bit color

BOTPAK	EQU		0x00280000		; load address of bootpack
DSKCAC	EQU		0x00100000		; disk cache location
DSKCAC0	EQU		0x00008000		; disk cache location (real mode)

; BOOT_INFO related
CYLS	EQU		0x0ff0			; boot sector setting
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; color information
SCRNX	EQU		0x0ff4			; resolution X
SCRNY	EQU		0x0ff6			; resolution Y
VRAM	EQU		0x0ff8			; start address of the graphics buffer

		ORG		0xc200			; memory address where this program is loaded

; Check whether VBE exists

		MOV		AX,0x9000
		MOV		ES,AX
		MOV		DI,0
		MOV		AX,0x4f00
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

; Check the VBE version

		MOV		AX,[ES:DI+4]
		CMP		AX,0x0200
		JB		scrn320			; if (AX < 0x0200) goto scrn320

; Get screen mode information

		MOV		CX,VBEMODE
		MOV		AX,0x4f01
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

; Confirm screen mode information
		CMP		BYTE [ES:DI+0x19],8		; number of colors must be 8
		JNE		scrn320
		CMP		BYTE [ES:DI+0x1b],4		; color specification method must be 4 (4 is palette mode)
		JNE		scrn320
		MOV		AX,[ES:DI+0x00]				; if bit7 of mode attributes is not 1, cannot add 0x4000
		AND		AX,0x0080
		JZ		scrn320					; bit7 of mode attributes is 0, so give up

;	Screen setup

		MOV		BX,VBEMODE+0x4000
		MOV		AX,0x4f02
		INT		0x10
		MOV		BYTE [VMODE],8	; screen mode (see C language reference)
		MOV		AX,[ES:DI+0x12]
		MOV		[SCRNX],AX
		MOV		AX,[ES:DI+0x14]
		MOV		[SCRNY],AX
		MOV		EAX,[ES:DI+0x28] ;VRAM address
		MOV		[VRAM],EAX
		JMP		keystatus

scrn320:
		MOV		AL,0x13						; VGA, 320x200x8bit color
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8		; record the screen mode (see C language)
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

;	Get the keyboard LED status via BIOS

keystatus:
		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

;	Disable all interrupts on the PIC
;	According to the AT compatible spec, to initialize the PIC,
;	you must do it before CLI, otherwise it may hang.
;	Initialize the PIC afterwards.

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; if OUT instructions are executed consecutively, some machines will not work properly
		OUT		0xa1,AL

		CLI						; disable CPU-level interrupts

;	To allow the CPU to access memory beyond 1MB, set A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

;	Switch to protected mode

		LGDT	[GDTR0]			; set temporary GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; set bit31 to 0 (disable paging)
		OR		EAX,0x00000001	; set bit0 to 1 (transition to protected mode)
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			; readable/writable segment, 32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; Transfer bootpack

		MOV		ESI,bootpack	; transfer source
		MOV		EDI,BOTPAK		; transfer destination
		MOV		ECX,512*1024/4
		CALL	memcpy

; Transfer disk data to its final location
; Start from the boot sector

		MOV		ESI,0x7c00		; transfer source
		MOV		EDI,DSKCAC		; transfer destination
		MOV		ECX,512/4
		CALL	memcpy

; The rest of it

		MOV		ESI,DSKCAC0+512	; transfer source
		MOV		EDI,DSKCAC+512	; transfer destination
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; convert from cylinder count to byte count /4
		SUB		ECX,512/4		; subtract the IPL offset
		CALL	memcpy

; Everything that asmhead must do is done here
; The rest is handled by bootpack

; Start bootpack

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; nothing to transfer
		MOV		ESI,[EBX+20]	; transfer source
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; transfer destination
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; initialize the stack
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02
		JNZ		waitkbdout	; if the AND result is not 0, jump to waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; if the subtraction result is not 0, jump to memcpy
		RET
; memcpy address prefix size

		ALIGNB	16
GDT0:
		RESB	8				; initial value
		DW		0xffff,0x0000,0x9200,0x00cf	; readable/writable segment, 32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; executable 32bit register (for bootpack)

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
