; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80 CP/M 2.2 BIOS
; ═══════════════════════════════════════════════════════════════════════
; + Является обратным портом ЮТ-88 CP/M 2.2 BIOS на МИКРО-80
; + Восстановление меток по публикации в МПСиС и CP/M Alteration Guide
; + Проведена небольшая оптимизация по размеру
; + Формирование структур диска сделана через библиотеку DISKDEF из CP/M Alteration Guide
; + Сделана поддержка не 4 модулей памяти (как в ЮТ-88), а 8-ми (как в МИКРО-80)
; todo В нижнем ОЗУ с DF00H только таблица переходов, а сам BIOS перенесен в верхнее ОЗУ на F000H

		CPU			8080
		Z80SYNTAX	EXCLUSIVE

		INCLUDE		CFG.INC

		ORG			BIOS

		INCLUDE		DSKDEF.MAC

		JP			BOOT
LDA03:	JP			WBOOT
		JP			0F812h	; CONST
		JP			0F803h	; CONIN
		JP			TERM	; CONOUT
		JP			0F809h	; LIST
		JP			0F80Ch	; PUNCH
		JP			0F806h	; READER
		JP			HOME
		JP			SELDSK
		JP			SETTRK
		JP			SETSEC
		JP			SETDMA
		JP			READ
		JP			WRITE
		LD			A,0FFh	; LISTST
		RET
		LD			B,00h	; SECTRAN
		EX			DE,HL
		ADD			HL,BC
		LD			A,(HL)
		LD			(SECTOR),A
		LD			L,A
		RET

WBOOT:  LD			SP,0080h
		LD			C,00h
		CALL		SELDSK
		CALL		HOME
		LD			B,2Ch		; количество блоков (CPP+BDOS)
		LD			C,00h		; дорожка
		LD			D,01h		; сектор
		LD			HL,CCP
LOAD1:	PUSH		BC
		PUSH		DE
		PUSH		HL
		LD			C,D
		CALL		SETSEC
		POP			BC
		PUSH		BC
		CALL		SETDMA
		CALL		READ
		;CP			00h
		OR			A
		JP			NZ,WBOOT
		POP			HL
		LD			DE,0080h
		ADD			HL,DE
		POP			DE
		POP			BC
		DEC			B
		JP			Z,GOCPM
		INC			D
		LD			A,D
		CP			09h			; сектор превысил максимум?
		JP			C,LOAD1
		LD			D,01h		; сектор
		INC			C			; дорожка
		PUSH		BC
		PUSH		DE
		PUSH		HL
		CALL		SETTRK
		POP			HL
		POP			DE
		POP			BC
		JP			LOAD1

BOOT:	LD			SP,0100h
		LD			HL,HELLO
		;CALL		PRINTSTR
		; --- START PROC PRINTSTR ---
PRINTSTR:
		LD			A,(HL)
		OR			A
		;RET		Z
		JP			Z, BOOT1
		LD			C,A
		CALL		TERM;0F809h
		INC			HL
		JP			PRINTSTR

BOOT1:	XOR			A
		LD			(0004h),A
		LD			(0003h),A

GOCPM:	DI				; А это зачем? У нас нет прерываний...
		LD			HL,BIOS+3
		LD			(0001h),HL
		LD			BC,0080h
		CALL		SETDMA
		LD			A,0C3h
		LD			(0000h),A
		LD			(0005h),A
		LD			HL, BDOS+6
		LD			(0006h),HL
		LD			A,(0004h)
		LD			C,A
		JP			CCP

		; --- START PROC SELDSK ---
SELDSK:	LD			HL,0000h
		LD			A,C
		;LD			(DISKNO),A
		OR			A
		RET			NZ
		;CP			01h
		;RET		NC
		;LD			A,(DISKNO)
		;LD			L,A
		;LD			H,00h
		;ADD		HL,HL
		;ADD		HL,HL
		;ADD		HL,HL
		;ADD		HL,HL
		;LD			DE,dpbase	;LDA33
		;ADD		HL,DE
		LD			HL,dpbase
		RET

		; --- START PROC HOME ---
HOME:	LD			C,00h

		; --- START PROC SETTRK ---
SETTRK:	LD			A, 11111110b	;0FEh
		LD			(DSKN),A
		LD			A,C
		CP			40h
		JP			C,LDB59
		SUB			40h
		LD			C,A

		LD			A, 11111101b	;0FDh
		LD			(DSKN),A
		LD			A,C
		CP			40h
		JP			C,LDB59
		SUB			40h
		LD			C,A

		LD			A, 11111011b	;0FBh
		LD			(DSKN),A
		LD			A,C
		CP			40h
		JP			C,LDB59
		SUB			40h
		LD			C,A

		LD			A, 11110111b	;0F7h
		LD			(DSKN),A
		LD			A,C
		CP			40h
		JP			C,LDB59
		SUB			40h
		LD			C,A

		LD			A, 11101111b	;0EFh
		LD			(DSKN),A
		LD			A,C
		CP			40h
		JP			C,LDB59
		SUB			40h
		LD			C,A

		LD			A, 11011111b	;0DFh
		LD			(DSKN),A
		LD			A,C
		CP			40h
		JP			C,LDB59
		SUB			40h
		LD			C,A

		LD			A, 10111111b	;0BFh
		LD			(DSKN),A
		LD			A,C
		CP			40h
		JP			C,LDB59
		SUB			40h
		LD			C,A

		LD			A, 01111111b	;07Fh
		LD			(DSKN),A

LDB59:	LD			HL,TRACK
		LD			(HL),C
		RET

		; --- START PROC SETSEC ---
SETSEC:	LD			HL,SECTOR
		LD			(HL),C
		RET

		; --- START PROC SETDMA ---
SETDMA:	LD			L,C
		LD			H,B
		LD			(DMAAD),HL
		RET

		; --- START PROC READ ---
READ:	CALL		COMAD
		LD			HL,0000h
		ADD			HL,SP
		LD			(OLDSP),HL
		LD			HL,(PHAD)
		LD			SP,HL
		LD			HL,(DMAAD)
		LD			B,64
		LD			A,(DSKN)
		OUT			(40h),A
RDSK:	POP			DE
		LD			(HL),E
		INC			HL
		LD			(HL),D
		INC			HL
		DEC			B
		JP			NZ,RDSK
ENDI0:	LD			A,0FFh
		OUT			(40h),A
		LD			HL,(OLDSP)
		LD			SP,HL
		XOR			A
		RET

WRITE:	CALL		COMAD
		ADD			HL,DE
		LD			(PHAD),HL
		LD			HL,0000h
		ADD			HL,SP
		LD			(OLDSP),HL
		LD			HL,(PHAD)
		LD			SP,HL
		LD			HL,(DMAAD)
		ADD			HL,DE
		DEC			HL
		LD			B,40h
		LD			A,(DSKN)
		OUT			(40h),A
WDSK:	LD			D,(HL)
		DEC			HL
		LD			E,(HL)
		DEC			HL
		PUSH		DE
		DEC			B
		JP			NZ,WDSK
		JP			ENDI0

		; --- START PROC COMAD ---
COMAD:	LD			HL,0000h
		LD			DE,0400h
		LD			A,(TRACK)
		OR			A
		JP			Z,LDBDA
LDBD5:	ADD			HL,DE
		DEC			A
		JP			NZ,LDBD5
LDBDA:	LD			DE,0080h
		LD			A,(SECTOR)
LDBE0:	DEC			A
		JP			Z,LDBE8
		ADD			HL,DE
		JP			LDBE0

LDBE8:	LD			(PHAD),HL
		RET

DSKN:	DS			1
TRACK:	DS			1
SECTOR:	DS			1
DMAAD:	DS			2
PHAD:	DS			2
OLDSP:	DS			2

;LDA33:  DW		XLT
;        DW		0,0,0
;		DW		DIRBUF
;		DW		DPB
;        DW		CSV
;        DW		ALV
;XLT:  	DB		1,2,3,4,5,6,7,8
;DPB:	DW		8		; spt	;Number of 128-byte records per track
;		DB		3		; bsh	;Block shift. 3 => 1k, 4 => 2k, 5 => 4k....
;		DB		7		; blm	;Block mask. 7 => 1k, 0Fh => 2k, 1Fh => 4k...
;		DB		0		; exm	;Extent mask, see later
;        DW		39		; dsm	;(no. of blocks on the disc)-1
;        DW		01Fh	; drm	;(no. of directory entries)-1
;        DB		080H	; al0	;Directory allocation bitmap, first byte
;        DB		0		; al1	;Directory allocation bitmap, second byte
;        DW		8		; cks	;Checksum vector size, 0 or 8000h for a fixed disc.
;						;		 No. directory entries/4, rounded up.
;        DW		6		; off	;Offset, number of reserved tracks

;       dn      is the disk number 0,1,...,n-1
;       fsc     is the first sector number (usually 0 or 1)
;       lsc     is the last sector number on a track
;       skf     is optional "skew factor" for sector translate
;       bls     is the data block size (1024,2048,...,16384)
;       dks     is the disk size in bls increments (word)
;       dir     is the number of directory elements (word)
;       cks     is the number of dir elements to checksum
;       ofs     is the number of tracks to skip (word)
;       [0]     is an optional 0 which forces 16K/directory entry

		disks		1
		diskdef		0, 1, 8, 1, 1024, 40+64+64+64+64+64+64+64, 40H, 32, 6
		endef

HELLO:	DB		01fh, 0ah, "*MikrO/80* CP/M V2.2", 0ah, 0
