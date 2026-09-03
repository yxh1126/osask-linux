; haribote-ipl
; TAB=4

CYLS	EQU		10				; declare CYLS=10

		ORG		0x7c00			; specify the program load address

; Standard FAT12 format floppy specific code

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; boot sector name (8 bytes)
		DW		512				; size of each sector (must be 512 bytes)
		DB		1				; cluster size (must be 1 sector)
		DW		1				; FAT start position (usually the first sector)
		DB		2				; number of FATs (must be 2)
		DW		224				; root directory size (usually 224 entries)
		DW		2880			; disk size (must be 2880 sectors, 1440*1024/512)
		DB		0xf0			; disk type (must be 0xf0)
		DW		9				; FAT length (must be 9 sectors)
		DW		18				; number of sectors per track (must be 18)
		DW		2				; number of heads (must be 2)
		DD		0				; no partition, must be 0
		DD		2880			; rewrite disk size once more
		DB		0,0,0x29		; meaning unknown (fixed)
		DD		0xffffffff		; (probably) volume serial number
		DB		"HARIBOTEOS "	; disk name (must be 11 bytes, padded with spaces)
		DB		"FAT12   "		; disk format name (must be 8 bytes, padded with spaces)
		RESB	18				; reserve 18 bytes

; Program body

entry:
		MOV		AX,0			; initialize registers
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; Read disk

		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; cylinder 0
		MOV		DH,0			; head 0
		MOV		CL,2			; sector 2
		MOV		BX,18*2*CYLS-1	; total number of sectors to read
		CALL	readfast		; tell it to read

; Reading done, jump to haribote.sys to execute!
		MOV		[0x0ff0],CH		; record how much IPL actually read
		JMP		0xc200

error:
		MOV		AX,0
		MOV		ES,AX
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; increment SI by 1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; display one character
		MOV		BX,15			; specify character color
		INT		0x10			; call video BIOS
		JMP		putloop
fin:
		HLT						; stop CPU, wait for instruction
		JMP		fin				; infinite loop
msg:
		DB		0x0a, 0x0a		; two newlines
		DB		"load error"
		DB		0x0a			; newline
		DB		0

readfast:	; use AL to read as much data as possible at once, starts here
; ES: read address, CH: cylinder, DH: head, CL: sector, BX: number of sectors to read

		MOV		AX,ES			; < compute the maximum value of AL from ES >
		SHL		AX,3			; divide AX by 32, store the result in AH (SHL is a left shift instruction)
		AND		AH,0x7f		; AH is the remainder of AH divided by 128 (512*128=64K)
		MOV		AL,128		; AL = 128 - AH; AH is the remainder of AH divided by 128 (512*128=64K)
		SUB		AL,AH

		MOV		AH,BL			; < compute the maximum value of AL from BX and store it in AH >
		CMP		BH,0			; if (BH != 0) { AH = 18; }
		JE		.skip1
		MOV		AH,18
.skip1:
		CMP		AL,AH			; if (AL > AH) { AL = AH; }
		JBE		.skip2
		MOV		AL,AH
.skip2:

		MOV		AH,19			; < compute the maximum value of AL from CL and store it in AH >
		SUB		AH,CL			; AH = 19 - CL;
		CMP		AL,AH			; if (AL > AH) { AL = AH; }
		JBE		.skip3
		MOV		AL,AH
.skip3:

		PUSH	BX
		MOV		SI,0			; register for counting the number of failures
retry:
		MOV		AH,0x02			; AH=0x02 : read disk
		MOV		BX,0
		MOV		DL,0x00			; drive A
		PUSH	ES
		PUSH	DX
		PUSH	CX
		PUSH	AX
		INT		0x13			; call disk BIOS
		JNC		next			; jump to next if no error occurred
		ADD		SI,1			; increment SI by 1
		CMP		SI,5			; compare SI with 5
		JAE		error			; jump to error if SI >= 5
		MOV		AH,0x00
		MOV		DL,0x00		; drive A
		INT		0x13			; reset drive
		POP		AX
		POP		CX
		POP		DX
		POP		ES
		JMP		retry
next:
		POP		AX
		POP		CX
		POP		DX
		POP		BX				; store the contents of ES into BX
		SHR		BX,5			; convert BX from 16-byte units to 512-byte units
		MOV		AH,0
		ADD		BX,AX			; BX += AL;
		SHL		BX,5			; convert BX from 512-byte units to 16-byte units
		MOV		ES,BX			; equivalent to ES += AL * 0x20;
		POP		BX
		SUB		BX,AX
		JZ		.ret
		ADD		CL,AL			; add AL to CL
		CMP		CL,18			; compare CL with 18
		JBE		readfast	; jump to readfast if CL <= 18
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readfast	; jump to readfast if DH < 2
		MOV		DH,0
		ADD		CH,1
		JMP		readfast
.ret:
		RET

		TIMES	0x1fe-($-$$) DB 0	; pad with 0x00 up to offset 0x7dfe

		DB		0x55, 0xaa
