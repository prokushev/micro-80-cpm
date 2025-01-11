; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80/ЮТ-88 CP/M 2.2 BIOS
; ═══════════════════════════════════════════════════════════════════════
; + Является обратным портом ЮТ-88 CP/M 2.2 BIOS на МИКРО-80
; + Восстановление меток по публикации в МПСиС и CP/M Alteration Guide
; + Проведена небольшая оптимизация по размеру
; + Формирование структур диска сделана через библиотеку DISKDEF из CP/M Alteration Guide
; + Сделана поддержка не 4 модулей памяти (как в ЮТ-88), а 8-ми (как в МИКРО-80)
; + Исправлено "запаздывание" отображения нажатых клавиш (баг в f803h M80/K)
; + Исправлено неверное количество зарезервированных дорожек
; todo В нижнем ОЗУ с DF00H только таблица переходов, а сам BIOS перенесен в верхнее ОЗУ на F000H
; + Поддержка принтера
; todo Поддержка автоповтора ввода на МИКРО-80 -> отказ от F803? Можно, для надежности, проверять
; наличие вектора F81B
; todo Поддержка перенаправления (IOByte)
; todo Фиксы косяков МОНИТОРов перенесены в эмулятор VT-52
; + BIOS исключен с диска, т.к. он оттуда никем и никогда не грузится, а место занимает.
; todo Совместить MON и BIOS?

	CPU			8080
	Z80SYNTAX	EXCLUSIVE

	INCLUDE		cfg.inc
	INCLUDE		syscalls.inc
	INCLUDE		vt52term.inc
	INCLUDE		dskdef.mac
	
	ORG		BIOS_ADDR


	JP	BOOT			;-3: Cold start routine
	JP	WBOOT			; 0: Warm boot - reload command processor
	JP	VT52_CST		; 3: Console status
	JP	VT52_CI			; 6: Console input
	JP	VT52_CO			; 9: Console output
	JP	ListCharFromC		;12: Printer output
	JP	TapeWriteByte		;15: Paper tape punch output
	JP	TapeReadByte		;18: Paper tape reader input
	JP	HOME			;21: Move disc head to track 0
	JP	SELDSK			;24: Select disc drive
	JP	SETTRK			;27: Set track number
	JP	SETSEC			;30: Set sector number
	JP	SETDMA			;33: Set DMA address
	JP	READ			;36: Read a sector
	JP	WRITE			;39: Write a sector
	LD	A,0FFh			;42: Status of list device
	RET

;SECTRAN (function 16)
;
;Translate sector numbers to take account of skewing.
;
;On entry, BC=logical sector number (zero based) and 
;DE=address of translation table. On exit, HL contains 
;physical sector number. On a system with hardware skewing, 
;this would normally ignore DE and return either BC or BC+1.

	if	0
	LD	B,00h			;45: Sector translation for skewing
	EX	DE,HL
	ADD	HL,BC
	LD	A,(HL)
	LD	(SECTOR),A
	LD	L,A
	RET
	else
	EX	DE, HL
	ADD	HL, BC
	LD	L, (HL)
	LD	H, 0
	RET
	endif

	if	M80FIX=1
CONIN:
	CALL	CONST			; Нажато что-нибудь?
	OR	A
	JP	Z,CONIN			; Ждем, пока ченить не нажмут
Unpress:
	CALL	GetKeyboardStatus	; Ждем отпускания
	INC	A		
	JP	Z, Unpress
	PUSH	HL
	LD	HL, LASTKEY
	LD	A,(HL)			; Читаем из буфера
	LD	(HL), 0			; Обнуляем буфер
	POP	HL
	RET
	
LASTKEY:	DB 0
CONST:
	LD	A,(LASTKEY)
	OR	A
	LD	A, 0FFH
	RET	NZ			; если в LASTKEY уже есть символ, то говорим, что нажато
	CALL	ReadKeyCode		; Если нажато, то читаем без ожидания символ в буфер
	INC	A
	RET	Z		; Если ничего не нажато, то выходим
	DEC	A
	LD	(LASTKEY), A
	LD	A, 0FFH		; Ставим статус, что нажато
	RET
	endif

	if	M80FIX=2
	endif

	
; WBOOT (п/п 1)
;
; Перезагружает командный процессор и BDOS.
; CCP и BDOS хранится на зарезервированных дорожках квазидиска.
;
; @todo: вообще, зачем грузить с квазидиска, если эти же данные есть на ROM-диске?
; Оттуда и грузим. Другой вопрос, что надо бы предусмотреть возможность замены
; BDOS и CPP.

WBOOT:  LD		SP,0080h
	LD		C,00h
	CALL		SELDSK
	CALL		HOME
	LD		B,(BIOS_ADDR-CCP_ADDR)/128; 2Ch количество блоков (CPP+BDOS)
	LD		C,00h		; дорожка
	LD		D,01h		; сектор
	LD		HL,CCP_ADDR
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
	LD		D,01h			; сектор
	INC		C			; дорожка
	PUSH		BC
	PUSH		DE
	PUSH		HL
	CALL		SETTRK
	POP		HL
	POP		DE
	POP		BC
	JP		LOAD1

; BOOT (п/п 0)
;
; Холодная загрузка. Выполняется при первом запуске системы.

BOOT:	LD		SP,0100h

	if	M80FIX=1
; ───────────────────────────────────────────────────────────────────────
; Проверяем наличие Микро-80 (Монитор РК)
; В этом МОНИТОРе неправильно реализован автоповтор, что приводит
; к "залипанию" в программах со связкой F812H/F803H.
; ───────────────────────────────────────────────────────────────────────

	LD	A, (0FFD8H)	; Проверяем наличие Микро-80 с М/80К
	CP	038H		; Буква 'm' от приветствия
	JP	NZ, NORMALF800	; Если нет, то работаем как обычно

	LD	DE, CONST
	LD	HL, BIOS_ADDR+6+1	; Патчим CONST
	LD	(HL), E
	INC	HL
	LD	(HL), D

	LD	DE, CONIN
	LD	HL, BIOS_ADDR+9+1	; Патчим CONIN
	LD	(HL), E
	INC	HL
	LD	(HL), D

NORMALF800:
	endif

	if	BIOS_HELLO
	LD	HL,HELLO
	CALL	VT52_MSG
	endif

BOOT1:	XOR	A
	LD	(0004h),A

;The IOBYTE lives at address 3 (in the Zero Page) and should be changed using BDOS calls 7 and 8 (get/set IOBYTE). The value is bitmapped:
;
;     Bits      Bits 6,7    Bits 4,5    Bits 2,3    Bits 0,1
;     Device    LIST        PUNCH       READER      CONSOLE
;
;     Value
;       00      TTY:        TTY:        TTY:        TTY:
;       01      CRT:        PTP:        PTR:        CRT:
;       10      LPT:        UP1:        UR1:        BAT:
;       11      UL1:        UP2:        UR2:        UC1:
;
;    BAT = batch mode. Use the current Reader for console input, and he current List (printer) device as the console output.
;    CRT = Standard console (keyboard and terminal screen).
;    LPT = Standard line printer.
;    PTP = Standard Paper Tape Punch.
;    PTR = Standard Paper Tape Reader.
;    TTY = Teletype device, eg a serial port.
;    UC1 = User defined (ie implementation dependent) console device.
;    UL1 = User defined (ie implementation dependent) printer device.
;    UPn = User defined (ie implementation dependent) output device.
;    URn = User defined (ie implementation dependent) input device. 
;
	LD	A, 10010101b
	LD	(0003h),A

GOCPM:	DI				; На некоторых машинах имеется но где тогда включать?
	LD	HL,BIOS_ADDR+3
	LD	(0001h),HL
	LD	BC,0080h
	CALL	SETDMA
	LD	A,0C3h
	LD	(0000h),A
	LD	(0005h),A
	LD	HL, BDOS_ADDR+6
	LD	(0006h),HL
	LD	A,(0004h)
	LD	C,A
	JP	CCP_ADDR

; SELDSK (п/п 9)
;
; Выбор привода диска, указанного в регистре C (0=A:, 1=B: ...).
; Called with E=0 or 0FFFFh.
;
; If bit 0 of E is 0, then the disc is logged in as if new;
; if the format has to be determined from the boot sector,
; for example, this will be done.
;
; If bit 0 if E is 1, then the disc has been logged in before.
; The disc is not accessed; the DPH address (or zero) is 
; returned immediately.
;
; SELDSK returns the address of a Disc Parameter Header in HL. 
; The exact format of a DPH varies between CP/M versions; note 
; that under CP/M 3, the DPH is in memory bank 0 and probably 
; not visible to programs. If the disc could not be selected 
; it returns HL=0.

SELDSK:	LD	HL,0000h
	LD	A,C
	OR	A
	RET	NZ
	LD	HL,dpbase
	RET

; HOME (п/п 8)
;
;Move the current drive to track 0.

HOME:	LD	C,00h

; SETTRK (п/п 10)
;
;Set the track in BC - 0 based.
; 

SETTRK:	
	if 1
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

; SETSEC (п/п 11)
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

;SETDMA (п/п 12)
;
;The next disc operation will read its data from 
;(or write its data to) the address given in BC.

SETDMA:	LD		L,C
	LD		H,B
	LD		(DMAAD),HL
	RET

;READ (п/п 13)
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
OLDSP	EQU		$+1
	LD		SP, 0		;OLDSP
	XOR		A
	RET

;WRITE (п/п 14)
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
	LD		B,40h
	ADD		HL,DE
	DEC		HL
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
LDBE8:	LD		(PHAD),HL
	RET		Z
;	JP		Z,LDBE8
	ADD		HL,DE
	JP		LDBE0

DSKN:	DS		1
TRACK:	DS		1
SECTOR:	DS		1
DMAAD:	DS		2
PHAD:	DS		2

;       dn      номер диска 0,1,...,n-1
;       fsc     номер первого сектора на дорожке (обычно 0 или 1)
;       lsc     номер последнего сектора на дорожке
;       skf     необязательный параметр "коэффициент сдвига" для преобразования номера сектора
;       bls     размер блока данных (1024,2048,...,16384)
;       dks     размер диска в блоках (word)
;       dir     число записей каталога (word)
;       cks     число контрольных записей каталога (определение факта смены диска)
;       ofs     число пропускаемых дорожек (word)
;       [0]     необязательный 0, который принудительно включает двухбайтные указатели блоков

; Для Микро-80 размер диска не 256кб, а 512Кб. В итоге при размере блока 1024 используется двухбайтные
; указатели блоков, что недопустимо. Поэтому надо увеличивать размер блока в два раза.

	disks		DISKSN
;	diskdef		0, 1, 8, 1, 1024, (64-6)+64*3, 64, 32, 6 ; Нормально для ЮТ-88, но нет для Микро-80
	diskdef		0, DISK_0_FSC, DISK_0_LSC, DISK_0_SKF, 2048, (32-3)+32*7, 64, 32, DISK_0_OFS
	endef

	if		BIOS_HELLO
HELLO:	DB		01fh, "*MikrO/80* CP/M 2.2", 0ah, 0
	else
	DB		0eah	; Это для того, чтобы буфер не удалялся из бинарника
	endif
