; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80/ЮТ-88 CP/M 2.2 BIOS
; ═══════════════════════════════════════════════════════════════════════
; + Является обратным портом ЮТ-88 CP/M 2.2 BIOS на МИКРО-80
; + Восстановление меток по публикации в МПСиС и CP/M Alteration Guide
; + Проведена небольшая оптимизация по размеру
; + Формирование структур диска сделана через библиотеку DISKDEF из CP/M Alteration Guide
; + Сделана поддержка не 4 модулей памяти (как в ЮТ-88), а 8-ми (как в МИКРО-80)
; + Исправлено "запаздывание" отображения нажатых клавиш (баг в f803h M80/K)
; todo В нижнем ОЗУ с DF00H только таблица переходов, а сам BIOS перенесен в верхнее ОЗУ на F000H
; + Поддержка принтера
; todo Поддержка автоповтора ввода на МИКРО-80 -> отказ от F803? Можно, для надежности, проверять
; наличие вектора F81B
; todo Поддержка перенаправления (IOByte)

	CPU			8080
	Z80SYNTAX	EXCLUSIVE

	INCLUDE		CFG.INC

	ORG		BIOS

	INCLUDE		DSKDEF.MAC

	JP		BOOT    ;-3: Cold start routine
	JP		WBOOT   ; 0: Warm boot - reload command processor
	JP		0F812h	; 3: Console status
	JP		0F803h	; 6: Console input
	JP		TERM	; 9: Console output
	JP		0F80FH	;12: Printer output
	JP		0F80Ch	;15: Paper tape punch output
	JP		0F806h	;18: Paper tape reader input
	JP		HOME	;21: Move disc head to track 0
	JP		SELDSK	;24: Select disc drive
	JP		SETTRK	;27: Set track number
	JP		SETSEC	;30: Set sector number
	JP		SETDMA	;33: Set DMA address
	JP		READ	;36: Read a sector
	JP		WRITE	;39: Write a sector
	LD		A,0FFh	;42: Status of list device
	RET

;SECTRAN (function 16)
;
;Translate sector numbers to take account of skewing.
;
;On entry, BC=logical sector number (zero based) and 
;DE=address of translation table. On exit, HL contains 
;physical sector number. On a system with hardware skewing, 
;this would normally ignore DE and return either BC or BC+1.

	LD		B,00h	;45: Sector translation for skewing
	EX		DE,HL
	ADD		HL,BC
	LD		A,(HL)
	LD		(SECTOR),A
	LD		L,A
	RET

CONIN:
	CALL	CONST		; Нажато что-нибудь?
	OR	A
	JP	Z,CONIN		; Ждем, пока ченить не нажмут
Unpress:
	CALL	0F812H		; Ждем отпускания
	INC	A		
	JP	Z, Unpress
	PUSH	HL
	LD	HL, LASTKEY
	LD	A,(HL)		; Читаем из буфера
	LD	(HL), 0		; Обнуляем буфер
	POP	HL
	RET
	
LASTKEY:	DB 0
CONST:
	LD	A,(LASTKEY)
	OR	A
	LD	A, 0FFH
	RET	NZ		; если в LASTKEY уже есть символ, то говорим, что нажато
	CALL	0F81BH		; Если нажато, то читаем без ожидания символ в буфер
	INC	A
	RET	Z		; Если ничего не нажато, то выходим
	DEC	A
	LD	(LASTKEY), A
	LD	A, 0FFH		; Ставим статус, что нажато
	RET

;WBOOT (function 1)
;
; Reloads the command processor and (on some systems) 
; the BDOS as well. How it does this is implementation-dependent;
; it may use the reserved tracks of a floppy disc or extra memory.

WBOOT:  LD		SP,0080h
	LD		C,00h
	CALL		SELDSK
	CALL		HOME
	LD		B,2Ch		; количество блоков (CPP+BDOS)
	LD		C,00h		; дорожка
	LD		D,01h		; сектор
	LD		HL,CCP
LOAD1:	PUSH		BC
	PUSH		DE
	PUSH		HL
	LD		C,D
	CALL		SETSEC
	POP		BC
	PUSH		BC
	CALL		SETDMA
	CALL		READ
	OR		A
	JP		NZ,WBOOT
	POP		HL
	LD		DE,0080h
	ADD		HL,DE
	POP		DE
	POP		BC
	DEC		B
	JP		Z,GOCPM
	INC		D
	LD		A,D
	CP		09h			; сектор превысил максимум?
	JP		C,LOAD1
	LD		D,01h		; сектор
	INC		C			; дорожка
	PUSH		BC
	PUSH		DE
	PUSH		HL
	CALL		SETTRK
	POP		HL
	POP		DE
	POP		BC
	JP		LOAD1

;BOOT (function 0)
;
;This function is completely implementation-dependent;
;and should never be called from user code.

BOOT:	LD		SP,0100h

; ───────────────────────────────────────────────────────────────────────
; Проверяем наличие Микро-80 (Монитор РК)
; В этом МОНИТОРе неправильно реализован автоповтор, что приводит
; к "залипанию" в программах со связкой F812H/F803H.
; ───────────────────────────────────────────────────────────────────────

	LD	A, (0FFD8H)	; Проверяем наличие Микро-80 с М/80К
	CP	038H		; Букава 'm' от приветствия
	JP	NZ, NORMALF800	; Если нет, то работаем как обычно

	LD	DE, CONST
	LD	HL, BIOS+6+1	; Патчим CONST
	LD	(HL), E
	INC	HL
	LD	(HL), D

	LD	DE, CONIN
	LD	HL, BIOS+9+1	; Патчим CONIN
	LD	(HL), E
	INC	HL
	LD	(HL), D

NORMALF800:
	LD	HL,HELLO
	CALL	0F818H

BOOT1:	XOR		A
	LD		(0004h),A
	LD		(0003h),A

GOCPM:;	DI				; А это зачем? У нас нет прерываний...
	LD		HL,BIOS+3
	LD		(0001h),HL
	LD		BC,0080h
	CALL		SETDMA
	LD		A,0C3h
	LD		(0000h),A
	LD		(0005h),A
	LD		HL, BDOS+6
	LD		(0006h),HL
	LD		A,(0004h)
	LD		C,A
	JP		CCP

;SELDSK (function 9)
;
;Select the disc drive in register C (0=A:, 1=B: ...).
;Called with E=0 or 0FFFFh.
;
;If bit 0 of E is 0, then the disc is logged in as if new;
;if the format has to be determined from the boot sector,
;for example, this will be done.
;
;If bit 0 if E is 1, then the disc has been logged in before.
;The disc is not accessed; the DPH address (or zero) is 
;returned immediately.
;
;SELDSK returns the address of a Disc Parameter Header in HL. 
;The exact format of a DPH varies between CP/M versions; note 
;that under CP/M 3, the DPH is in memory bank 0 and probably 
;not visible to programs. If the disc could not be selected 
;it returns HL=0.

SELDSK:	LD		HL,0000h
	LD		A,C
	OR		A
	RET		NZ
	LD		HL,dpbase
	RET

;HOME (function 8)
;
;Move the current drive to track 0.

HOME:	LD		C,00h

;SETTRK (function 10)
;
;Set the track in BC - 0 based.
; 

SETTRK:	
	if 0
	LD	A, 40H
	ADD	A, C
	LD	B, 11111110b
LOOP:	SUB	40H
	LD	C, A
	JP	C, EXLOOP
	LD	A, B
	RLCA
	LD	B, A
	LD	A, C
	JP	LOOP
EXLOOP:	LD	A, B
	LD	(DSKN),A
	else
	LD		A, 11111110b	;0FEh
	LD		(DSKN),A
	LD		A,C
	CP		40h
	JP		C,LDB59         ; A<40
	SUB		40h
	LD		C,A

	LD		A, 11111101b	;0FDh
	LD		(DSKN),A
	LD		A,C
	CP		40h
	JP		C,LDB59
	SUB		40h
	LD		C,A

	LD		A, 11111011b	;0FBh
	LD		(DSKN),A
	LD		A,C
	CP		40h
	JP		C,LDB59
	SUB		40h
	LD		C,A

	LD		A, 11110111b	;0F7h
	LD		(DSKN),A
	LD		A,C
	CP		40h
	JP		C,LDB59
	SUB		40h
	LD		C,A

	LD		A, 11101111b	;0EFh
	LD		(DSKN),A
	LD		A,C
	CP		40h
	JP		C,LDB59
	SUB		40h
	LD		C,A

	LD		A, 11011111b	;0DFh
	LD		(DSKN),A
	LD		A,C
	CP		40h
	JP		C,LDB59
	SUB		40h
	LD		C,A

	LD		A, 10111111b	;0BFh
	LD		(DSKN),A
	LD		A,C
	CP		40h
	JP		C,LDB59
	SUB		40h
	LD		C,A

	LD		A, 01111111b	;07Fh
	LD		(DSKN),A
	endif
LDB59:	LD		HL,TRACK
	LD		(HL),C
	RET

;SETSEC (function 11)
;
;Set the sector in BC. Under CP/M 1 and 2 a sector 
;is 128 bytes. Under CP/M 3 the sector size is given
;in the Disk Parameter Block.
;
; TODO:
;There has been discussion in comp.os.cpm about whether
;the parameter to this function is a byte or a word. 
;The conclusion (based on examining the BDOS source) 
;was that it is a word.

SETSEC:	LD		HL,SECTOR
	LD		(HL),C
	RET

;SETDMA (function 12)
;
;The next disc operation will read its data from 
;(or write its data to) the address given in BC.

SETDMA:	LD		L,C
	LD		H,B
	LD		(DMAAD),HL
	RET

;READ (function 13)
;
;Read the currently set track and sector at the 
;current DMA address. Returns A=0 for OK, 1 for 
;unrecoverable error, 0FFh if media changed.

READ:	CALL		COMAD
	LD		HL,0000h
	ADD		HL,SP
	LD		(OLDSP),HL
	LD		HL,(PHAD)
	LD		SP,HL
	LD		HL,(DMAAD)
	LD		B,40h
	LD		A,(DSKN)
	OUT		(40h),A
RDSK:	POP		DE
	LD		(HL),E
	INC		HL
	LD		(HL),D
	INC		HL
	DEC		B
	JP		NZ,RDSK
ENDI0:	LD		A,0FFh
	OUT		(40h),A
	LD		HL,(OLDSP)
	LD		SP,HL
	XOR		A
	RET

;WRITE (function 14)
;
;Write the currently set track and sector. C contains a deblocking code:
;
;C=0 - Write can be deferred
;C=1 - Write must be immediate
;C=2 - Write can be deferred, no pre-read is necessary.
;
;Returns A=0 for OK, 1 for unrecoverable error, 2 if disc is readonly,
;0FFh if media changed.

WRITE:	CALL		COMAD
	ADD		HL,DE
	LD		(PHAD),HL
	LD		HL,0000h
	ADD		HL,SP
	LD		(OLDSP),HL
	LD		HL,(PHAD)
	LD		SP,HL
	LD		HL,(DMAAD)
	ADD		HL,DE
	DEC		HL
	LD		B,40h
	LD		A,(DSKN)
	OUT		(40h),A
WDSK:	LD		D,(HL)
	DEC		HL
	LD		E,(HL)
	DEC		HL
	PUSH		DE
	DEC		B
	JP		NZ,WDSK
	JP		ENDI0

	; --- START PROC COMAD ---
COMAD:	LD		HL,0000h
	LD		DE,0400h
	LD		A,(TRACK)
	OR		A
	JP		Z,LDBDA
LDBD5:	ADD		HL,DE
	DEC		A
	JP		NZ,LDBD5
LDBDA:	LD		DE,0080h
	LD		A,(SECTOR)
LDBE0:	DEC		A
	JP		Z,LDBE8
	ADD		HL,DE
	JP		LDBE0

LDBE8:	LD		(PHAD),HL
	RET

DSKN:	DS		1
TRACK:	DS		1
SECTOR:	DS		1
DMAAD:	DS		2
PHAD:	DS		2
OLDSP:	DS		2

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

HELLO:	DB		01fh, "*MikrO/80* CP/M V2.2", 0ah, 0
