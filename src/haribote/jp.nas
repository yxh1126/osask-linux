; haribote-ipl
; TAB=4

CYLS	EQU		20				; how many cylinders to read

		ORG		0x7c00			; where this program is loaded

; Standard FAT12 floppy disk format description

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; boot sector name (8 bytes, can be anything)
		DW		512				; sector size (must be 512)
		DB		1				; cluster size (must be 1 sector)
		DW		1				; where FAT starts (usually from sector 1)
		DB		2				; number of FATs (must be 2)
		DW		224				; root directory size (usually 224 entries)
		DW		2880			; drive size (must be 2880 sectors)
		DB		0xf0			; media type (must be 0xf0)
		DW		9				; FAT area length (must be 9 sectors)
		DW		18				; sectors per track (must be 18)
		DW		2				; number of heads (must be 2)
		DD		0				; no partition, must be 0
		DD		2880			; write drive size again
		DB		0,0,0x29		; unknown but should be set to this value
		DD		0xffffffff		; probably volume serial number
		DB		"HARIBOTEOS "	; disk name (11 bytes)
		DB		"FAT12   "		; format name (8 bytes)
		RESB	18				; reserve 18 bytes for now

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
		MOV		SI,0			; count failures
retry:
		MOV		AH,0x02			; AH=0x02: disk read
		MOV		AL,1			; 1 sector
		MOV		BX,0
		MOV		DL,0x00			; drive A
		INT		0x13			; call disk BIOS
		JNC		next			; if no error, go to next
		ADD		SI,1			; increment SI
		CMP		SI,5			; compare SI with 5
		JAE		error			; if SI >= 5, go to error
		MOV		AH,0x00
		MOV		DL,0x00			; drive A
		INT		0x13			; reset drive
		JMP		retry
next:
		MOV		AX,ES			; advance address by 0x200
		ADD		AX,0x0020
		MOV		ES,AX			; no "ADD ES,0x020" instruction, so do this
		ADD		CL,1			; increment CL
		CMP		CL,18			; compare CL with 18
		JBE		readloop		; if CL <= 18, go to readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; if DH < 2, go to readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; if CH < CYLS, go to readloop

; Reading done, now execute haribote.sys!

		MOV		[0x0ff0],CH		; record how far IPL read
		JMP		0xc200

error:
		MOV		AX,0
		MOV		ES,AX
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; increment SI
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; display one character function
		MOV		BX,15			; color code
		INT		0x10			; call video BIOS
		JMP		putloop
fin:
		HLT						; halt CPU until something happens
		JMP		fin				; infinite loop
msg:
		DB		0x0a, 0x0a		; two newlines
		DB		"load error"
		DB		0x0a			; newline
		DB		0

		RESB	0x7dfe-$		; fill with 0x00 up to 0x7dfe

		DB		0x55, 0xaa
