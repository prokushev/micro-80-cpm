; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80 CP/M 2.2 ЗАГРУЗЧИК
; ═══════════════════════════════════════════════════════════════════════
; + Обратный порт ЮТ-88 CP/M 2.2 на МИКРО-80
; + Загрузка загрузчика в произвольные адреса
; + Образ квазидиска теперь содержит полный набор Directory (нет "пустых" файлов по DIR)
; + Загрузчик позволяет не затирать существующие данные на квазидиске
; + CH.COM добавлен в образ квазидиска
; todo CP/M размещается в соответствии с верхней границей памяти
; todo Восстановление диска с ленты / Автоопределение объема квазидиска
; todo Исключить BIOS с диска, т.к. он оттуда никем и никогда не грузится, а место занимает.



	CPU		8080
	Z80SYNTAX	EXCLUSIVE
	
	INCLUDE		"CFG.INC"
	INCLUDE		"syscalls.inc"

	ORG		3100h		; По факту грузить можем в любые адреса

Start:

; ───────────────────────────────────────────────────────────────────────
; Определяем адрес запуска программы
; выход: DE=BaseAddress
; ───────────────────────────────────────────────────────────────────────
	LD	HL, (0)			; эта область затрется при загрузке с 0..2
	EX	DE, HL			; DE=(0)
	LD	HL, 0E9E1H		; POP HL ! JP(HL)
	LD	(0), HL
	RST	0			; HL=BaseAddress
BaseAddress:
; ───────────────────────────────────────────────────────────────────────
; Устанавливаем по адресу RST 0 переход на обработчик относительного
; адреса
; ───────────────────────────────────────────────────────────────────────
	LD	A, 0C3H			; JMP ...
	LD	(0), A
	LD	A, (2)			; Сохраняем данные
	LD	BC, RST0-BaseAddress	; Смещение до обработчика
	ADD	HL, BC			; HL=RST0
	LD	(1), HL			; Адрес обработчика RST 0
	EX	DE, HL			; DE=RST0, HL=(0)
; ───────────────────────────────────────────────────────────────────────
; Сохраняем данные адресов 0-2 для последующего восстановления
; ───────────────────────────────────────────────────────────────────────
	RST	0
	LD	((RST0_0-$) & 0ffffh), HL
	RST	0
	LD	((RST0_2-$) & 0ffffh), A

	RST	0
	LD	HL, L3120-$
	RST	0
	LD	(Patch1+1-$), HL
	RST	0
	LD	(Patch2+1-$), HL

	RST	0
	LD	HL, HELLO-$
	CALL	PrintString

	; Перемещение CCP/BDOS/BIOS по итоговым адресам
	; (адреса перебираются снизу вверх)
	RST	0
	LD	HL, DISKIMAGE-$
	LD	DE, CCP
	RST	0
	LD	BC, ENDC-$
COPYLOOP:
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,H
	CP	B
	RST	0
	JP	NZ,COPYLOOP-$
	LD	A,L
	CP	C
	RST	0
	JP	NZ,COPYLOOP-$

	; Перемещение эмулятора терминала по итоговым адресам
	
	RST	0
	LD	HL,TERMIMAGE-$
	LD	DE,TERM
	RST	0
	LD	BC,TERMIMAGEEND-$
L3135:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,H
	CP	B
	RST	0
	JP	NZ,L3135-$
	LD	A,L
	CP	C
	RST	0
	JP	NZ,L3135-$

	;
MenuLoop:
	RST	0
	LD	HL, MENU-$
	CALL	PrintString
	CALL	InputSymbol

	CP	'3'
	JP	Z, BIOS

	CP	'2'
	RST	0
	JP	Z, InitDisk-$

;	CP	'1'
;	RST	0
;	JP	Z, LoadDisk-$

	CP	'1'
	RST	0
	JP	Z, InitSystem-$

	RST	0
	JP	MenuLoop-$

InitSystem:
	RST	0
	LD	HL,ENDC-1-$
	RST	0
	LD	BC,DISKIMAGE-1-$
	LD	SP,ENDC-DISKIMAGE
	RST	0
	JP	Copy-$

InitDisk:
	; Сохранение копии CP/M на квазидиске
	; (адреса перебираются сверху вниз)
	RST	0
	LD	HL,ENDDISKIMAGE-$
	RST	0
	LD	BC,DISKIMAGE-1-$
	LD	SP,ENDDISKIMAGE-DISKIMAGE+1

;	Дальше нельзя CALL, RST	
Copy:	LD	A,0FEh
	OUT	(40h),A			; Подключаем первые 64кб RAMDISKа

L3120:	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	DEC	HL
	PUSH	DE
	LD	A,H
	CP	B
Patch1:
	JP	NZ,L3120
	LD	A, L
	CP	C
Patch2:
	JP	NZ,L3120

	LD	A,0FFh
	OUT	(40h),A			; Отключаем RAMDISK
;	Дальше можно CALL, RST	

	JP	BIOS			; Холодный старт BIOS

; ───────────────────────────────────────────────────────────────────────
; Загрузчик образа диска с ленты
; ───────────────────────────────────────────────────────────────────────

LoadDisk:
	JP	BIOS		; Холодный старт

; ───────────────────────────────────────────────────────────────────────
; Подпрограмма модификации относительного адреса
; ───────────────────────────────────────────────────────────────────────
RST0:	EX	(SP),HL		; Save H,L and get next PC
	PUSH	DE		; Save D,E.
	PUSH	AF		; Save condition codes.
	DEC	HL		; Change RST 0 to NOP.
	LD	(HL),00H
	INC	HL

	INC	HL
	LD	E,(HL)		; Get relative addr. in D, E.
	INC	HL
	LD	D,(HL)
	EX	DE,HL		; Add offset for abs. addr.
	ADD	HL,DE
	EX	DE,HL
	DEC	DE		; Set to beginning of instr
	DEC	DE
	LD	(HL),D		; Store absolute addr.
	DEC	HL
	LD	(HL),E
	POP	AF		; Restore condition codes.
	POP	DE		; Restore D,E.
	DEC	HL		; Set H,L to start of instr
	EX	(SP),HL		; Restore H,L
	RET

RST0_0	DW	0
RST0_2:	DB	0

HELLO:	DB	1FH, "zagruz~ik CP/M-80 2.2", 0dh, 0ah, 0
MENU:	;DB	"1. zagruzitx disk s mg", 0dh, 0ah
	DB	"1. wosstanowitx sistemu na diske", 0dh, 0ah
	DB	"2. sozdatx nowyj pustoj disk", 0dh, 0ah
	DB	"3. ispolxzowatx teku}ij disk", 0dh,0ah
	DB	"=>"
	DB	0

TERMIMAGE:
	BINCLUDE	TERM.BIN
TERMIMAGEEND:

	; Образ квазидиска - системная часть
	ORG		3400H
DISKIMAGE:
	BINCLUDE	CCP.BIN		; size=800H
	ORG		3400H+800H
	BINCLUDE	BDOS.BIN		; size=E00H
	ORG		3400H+1600H
	; @TODO: Исключить BIOS?
	BINCLUDE	BIOS.BIN		; size=300H
	DB	3400H+1C00H-$ DUP (0FFH)	; Резервирем 7 дорожек
ENDC	EQU		$

	; Продолжение образа квазидиска - директория и данные

	;CP/M 2.2 directory
	;
	;The CP/M 2.2 directory has only one type of entry:
	;
	;UU F1 F2 F3 F4 F5 F6 F7 F8 T1 T2 T3 EX S1 S2 RC   .FILENAMETYP....
	;AL AL AL AL AL AL AL AL AL AL AL AL AL AL AL AL   ................
	;
	;UU = User number. 0-15 (on some systems, 0-31). The user number allows multiple
	;    files of the same name to coexist on the disc. 
	;     User number = 0E5h => File deleted
	;Fn - filename
	;Tn - filetype. The characters used for these are 7-bit ASCII.
	;       The top bit of T1 (often referred to as T1') is set if the file is 
	;     read-only.
	;       T2' is set if the file is a system file (this corresponds to "hidden" on 
	;     other systems). 
	;EX = Extent counter, low byte - takes values from 0-31
	;S2 = Extent counter, high byte.
	;
	;      An extent is the portion of a file controlled by one directory entry.
	;    If a file takes up more blocks than can be listed in one directory entry,
	;    it is given multiple entries, distinguished by their EX and S2 bytes. The
	;    formula is: Entry number = ((32*S2)+EX) / (exm+1) where exm is the 
	;    extent mask value from the Disc Parameter Block.
	;
	;S1 - reserved, set to 0.
	;RC - Number of records (1 record=128 bytes) used in this extent, low byte.
	;    The total number of records used in this extent is
	;
	;    (EX & exm) * 128 + RC
	;
	;    If RC is >=80h, this extent is full and there may be another one on the 
	;    disc. File lengths are only saved to the nearest 128 bytes.
	;
	;AL - Allocation. Each AL is the number of a block on the disc. If an AL
	;    number is zero, that section of the file has no storage allocated to it
	;    (ie it does not exist). For example, a 3k file might have allocation 
	;    5,6,8,0,0.... - the first 1k is in block 5, the second in block 6, the 
	;    third in block 8.
	;     AL numbers can either be 8-bit (if there are fewer than 256 blocks on the
	;    disc) or 16-bit (stored low byte first). 

	ORG	3400H+1C00H	;было 4D00H	
	DB	0,"CH      COM", 0, 0, 0, 06H		; 6=size/128
	DB	2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		; 2=start block
	DB	64*32-1*32 DUP (0E5H)

	BINCLUDE CH.COM
	DB	($ & 0ff80h)+80h-$ dup (0)	;выравниваем на размер записи

ENDDISKIMAGE	EQU	$-1

