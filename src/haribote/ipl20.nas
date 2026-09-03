; haribote-ipl
; TAB=4

CYLS	EQU		20				; declare CYLS=20

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
		TIMES	18 DB 0			; reserve 18 bytes

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
readloop:
		MOV		SI,0			; register to record the number of failures
retry:
		MOV		AH,0x02			; AH=0x02 : read disk
		MOV		AL,1			; 1 sector
		MOV		BX,0
		MOV		DL,0x00			; drive A
		JMP		retry
next:
		MOV		AX,ES			; shift the memory address back by 0x200 (512/16 hex conversion)
		ADD		AX,0x0020
		MOV		ES,AX			; ADD ES,0x020 since there is no ADD ES, do it via AX
		ADD		CL,1			; add 1 to CL
		CMP		CL,18			; compare CL with 18
		JBE		readloop		; jump to readloop if CL <= 18
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; jump to readloop if DH < 2
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; jump to readloop if CH < CYLS

; Reading done, jump to haribote.sys to execute!
		MOV		[0x0ff0],CH		; note how far IPL has read
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

		TIMES	0x1fe-($-$$) DB 0		; pad with 0x00 until 0x001fe

		DB		0x55, 0xaa
