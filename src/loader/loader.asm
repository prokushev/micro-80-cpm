; ═══════════════════════════════════════════════════════════════════════
; ЗАГРУЗЧИК ЮТ-88/МИКРО-80 CP/M 2.2 
; ═══════════════════════════════════════════════════════════════════════
; + Обратный порт ЮТ-88 CP/M 2.2 на МИКРО-80
; + Загрузка загрузчика в произвольные адреса
; + Образ квазидиска теперь содержит полный набор Directory (нет "пустых" файлов по DIR)
; + Загрузчик позволяет не затирать существующие данные на квазидиске
; + CH.COM добавлен в образ квазидиска
; todo CP/M размещается в соответствии с верхней границей памяти
; todo Автоопределение объема квазидиска
; + Исключен BIOS с диска, т.к. он оттуда никем и никогда не грузится, а место занимает.
; + Автоопределение терминала VT-52 и автозагрузка эмулятора терминала, если не найден терминал.
; + Проверка наличия квазидиска
; todo Загрузка CP/M из адресов, не кратным 256 (уменьшение размера загрузчика)



	CPU		8080
	Z80SYNTAX	EXCLUSIVE
	
	INCLUDE		"cfg.inc"
	INCLUDE		"syscalls.inc"

BASE	EQU             0h
	ORG		BASE		; По факту грузить можем в любые адреса

; ───────────────────────────────────────────────────────────────────────
; Макросы для относительного перехода относительно текущего адреса.
; Не работает для первого операнда:
; REL LD Label1, HL - не работает
; ───────────────────────────────────────────────────────────────────────

REL	MACRO	CMD, ADDR
	RST	0
	IF	ARGCOUNT==2
	CMD, (ADDR-$) & 0ffffh
	ELSE
	CMD-$
	ENDIF
	ENDM

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

	REL	LD HL, L3120-$
	RST	0
	LD	(Patch1+1-$), HL
	RST	0
	LD	(Patch2+1-$), HL

	; Защита от нажатой клавиши при запуске (чтобы не сбоил детект терминала)
Unpress:
	CALL	GetKeyboardStatus	; Ждем отпускания
	INC	A
	REL	JP Z, Unpress

	REL	LD HL, HELLO
	CALL	PrintString

	; Проверяем наличие VT-52
	REL	CALL VT52DETECT

	REL	LD HL, VT52PRESENT

	; Если VT-52 найден, то сообщаем об том
	PUSH	AF
	CALL	Z, PrintString
	POP	AF

	; Если VT-52 не найден, то устанавливаем эмулятор
	PUSH	AF
	REL	CALL NZ, VT52INSTALL
	POP	AF
	REL	CALL Z, MONINSTALL
	
	; Ищем RAM-диск
	LD	HL, 0
	ADD	HL, SP
	EX	DE, HL			; Запомнили стек

	LD	HL, (0)			; Сохранили данные по адресу 0 (там что-то типа xxC3h)
	LD	SP, 0			; Настроили адрес диска
	LD	A,0FEh
	OUT	(40h),A			; Подключаем первые 64кб RAMDISKа

	POP	BC			; Считали данные с диска
	
	LD	A,0FFh
	OUT	(40h),A			; Отключаем RAMDISK

	EX	DE, HL
	LD	SP, HL			; Восстановили стек

	; Сравниваем DE с BC
	; Данные совпали => нет диска
	LD	A,B
	CP	D
	REL	JP NZ, DISKOK
	LD	A,C
	CP	E
	REL	JP NZ, DISKOK

	REL	JP Z, NODISK

DISKOK:
	REL	LD HL, DISKFOUND
	CALL	PrintString

	; Проверяем, есть ли п/п определения RAMTOP
	REL	LD HL, MAXMEM
	CALL	PrintString

	; В этой точке входа может быть JP ... или LD HL,(...)
	LD	A, (GetFreeMemAddr)
	CP	0C3H			; JP ...
	REL	JP Z, APIPRESENT

	CP	02AH			; LD HL, (...)
	REL	JP Z, APIPRESENT
	
	; У нас нет API для определения верхней границы памяти.
	; Значит это:
	; - Микро-80 с оригинальным МОНИТОРом
	; - ЮТ-88 с МОНИТОРом U
	; - Микроша с оригинальным МОНИТОРом
	; - что-то еще из относительно старого
	;
	; Микрошу можно попробовать определить по символу на экране через адрес в служебной ячейке
	; ЮТ-88 и Микро-80 можно попробовать определить тоже по символу на экране или просто сканирование
	; остановится, т.к. считать данные с экрана в ЮТ-88 и Микро-80 можно не во всех вариантах.

	; Начинаем сканировать память с RAMSTART и дальше
	LD	HL, RAMSTART
	INC	H
	LD	L, 0

NextPage:
	INC	H
	LD	C,(HL)
	LD	(HL),0EFH
	LD	A, (HL)
	LD	(HL), C
	CP	0EFH
	REL	JP Z, NextPage

	DEC	H
	LD	L, 0FFH
	
	; Теперь надо как-то определиться с картой памяти, т.к. здесь и видео-ОЗУ и системные ячейки и пр.
	
	REL	JP PrintMem

APIPRESENT:

	CALL	GetFreeMemAddr
PrintMem:
	LD	A, H
	CALL	PrintHexByte
	LD	A, L
	CALL	PrintHexByte
	
	; Перемещение CCP/BDOS по итоговым адресам
	; (адреса перебираются снизу вверх)
	REL	LD HL, DISKIMAGE
	LD	DE, CCP_ADDR
	REL	LD BC, ENDC
COPYLOOP:
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,H
	CP	B
	REL	JP NZ,COPYLOOP
	LD	A,L
	CP	C
	REL	JP NZ,COPYLOOP

	; Перемещение BIOS по итоговым адресам
	; (адреса перебираются снизу вверх)
	REL	LD HL, BIOSIMAGE-$
	LD	DE, BIOS_ADDR
	REL	LD BC, BIOSIMAGEEND-$
COPYLOOP2:
	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,H
	CP	B
	REL	JP NZ,COPYLOOP2
	LD	A,L
	CP	C
	REL	JP NZ,COPYLOOP2

	;
MenuLoop:
	REL	LD HL, MENU
	CALL	PrintString
	CALL	InputSymbol

	CP	'3'
	JP	Z, BIOS_ADDR

	CP	'2'
	REL	JP Z, InitDisk

	CP	'1'
	REL	JP Z, InitSystem

	REL	JP MenuLoop

InitSystem:
	RST	0
	LD	HL,ENDC-1-$
	RST	0
	LD	BC,DISKIMAGE-1-$
	LD	SP,ENDC-DISKIMAGE
	RST	0			; !!!!todo глюка!!!
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

	JP	BIOS_ADDR		; Холодный старт BIOS

NODISK:
	REL	LD HL, NODISKMSG
	CALL	PrintString
	CALL	InputSymbol
	JP	WarmBoot

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
	DEC	HL		; Set H,L to start of instr

	POP	AF		; Restore condition codes.
	POP	DE		; Restore D,E.
	EX	(SP),HL		; Restore H,L
	RET

;---------------------------------------------------
; Определение наличия терминала VT-52
; ВХОД
;	нет
; ВЫХОД
;	A=0 - есть терминала
;	A<>0 - нет терминала
;	не установлен Z - нет терминала
;---------------------------------------------------
VT52DETECT:
	REL	LD HL, VT52
	CALL	PrintString
	CALL	GetKeyboardStatus	; По идее, надо ждать с тайм-аутом, т.к. терминал может быть асинхронным
	INC	A
	RET	NZ
	CALL	InputSymbol
	CP	1BH
	RET	NZ
	CALL	GetKeyboardStatus	; По идее, надо ждать с тайм-аутом, т.к. терминал может быть асинхронным
	INC	A
	RET	NZ
	CALL	InputSymbol
	CP	'/'
	RET	NZ
	CALL	GetKeyboardStatus	; По идее, надо ждать с тайм-аутом, т.к. терминал может быть асинхронным
	INC	A
	RET	NZ
	CALL	InputSymbol
	CP	'K'		; VT-52
	REL	JP Z, VDFOUND
	CP	'L'		; VT-52 + Copier
	REL	JP Z, VDFOUND
	CP	'M'		; VT-52 + Printer
	REL	JP Z, VDFOUND
	CP	'Z'		; VT-100 or similar in VT-52 Emulation mode
	RET	NZ
VDFOUND:XOR	A		
	RET

	; Перемещение эмулятора терминала по итоговым адресам
VT52INSTALL:	
	REL	LD HL,VT52TERMIMAGE
	LD	DE,TERM_ADDR
	REL	LD BC,VT52TERMIMAGEEND
L3135:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,H
	CP	B
	REL	JP NZ,L3135
	LD	A,L
	CP	C
	REL	JP NZ,L3135
	REL	LD HL, VT52NOTPRESENT
	CALL	PrintString
	RET

MONINSTALL:	
	REL	LD HL,MONTERMIMAGE
	LD	DE,TERM_ADDR
	REL	LD BC,MONTERMIMAGEEND
LL3135:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	LD	A,H
	CP	B
	RST	0
	JP	NZ,LL3135-$
	LD	A,L
	CP	C
	RST	0
	JP	NZ,LL3135-$
	RST	0
	LD	HL, MONPRESENT-$
	CALL	PrintString
	RET


RST0_0	DW	0
RST0_2:	DB	0

	; Образ квазидиска - системная часть (зарезервированные дорожки)
	; Количество зарезервированных дорожек - размер системы/(размер сектора*количество секторов на дорожку)
	; Округляется в большую сторону кратно размеру дорожки.

	ORG		BASE+300H
DISKIMAGE:
	BINCLUDE	CCP.BIN			; size=800H
	ORG		BASE+300H+800H
	BINCLUDE	BDOS.BIN		; size=E00H
	DB	BASE+300H+1800H-$ DUP (0FFH)	; Резервирем 6 дорожек
ENDC	EQU		$

	; Продолжение образа квазидиска - директория и данные.
	; Начало каталога на первой дорожке, после зарезервированных.

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

	ORG	BASE+300H+1800H	;было 4D00H	
	DB	0,"CH      COM", 0, 0, 0, (CHEND-CHSTART)/128		; 6=size/128
	DB	1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		; 1=start block
	DB	64*32-1*32 DUP (0E5H)

CHSTART:
	BINCLUDE CH.COM
	DB	($ & 0ff80h)+80h-$ dup (0)	;выравниваем на размер записи
CHEND:

ENDDISKIMAGE	EQU	$-1

BIOSIMAGE:
	BINCLUDE	BIOS.BIN		; size=300H
BIOSIMAGEEND:

MONTERMIMAGE:
	BINCLUDE	MONTERM.BIN
MONTERMIMAGEEND:

VT52TERMIMAGE:
	BINCLUDE	VT52TERM.BIN
VT52TERMIMAGEEND:

	if	1
	Z80SYNTAX OFF
; ********************************************************
; * ПЕРЕМЕЩАЮЩИЙ ЗАГРУЗЧИК ОБЪЕКТНЫХ ПРОГРАММНЫХ МОДУЛЕЙ *
; * для радиолюбительского компьютра "Радио-86РК"        *
; ********************************************************
; Внимание! Эта программа должна загружаться с адреса 0000Н 
; и использовать заранее созданнум ВIТМАР-тавлицу           
; Вызовы резидентного монитора Радио-86РК
GETMEM:	EQU 	0F830H 	; Вернуть значение МАХRАМ в (HL)
PUTMEM:	EQU 	0F833H 	; Заменить MAXRAM на содержимое (HL)
	ORG 	0
INIT: 	JMP 	START 	; Основной вход в аагрузчик с авто-
GO_ADR:	EQU 	INIT+1 	; установкой aдреса по МАХRАМ.
INIT1: 	JMP 	START1 	; Вход без автоустановки адреса
TOPS: 	DB 	0 	; Младший байт длины программы TASK
BLOCKS: DB 	0 	; Старший байт длины программы TASK
			; TOPS&BLOCKS вместе содержат 16-
			; битное представлние верхней грани-
 			; цы прикладной программы.
ASTART: DB 	0 	; Адрес начала области перемещения
SHIFT: 	DB 	0 	; (16-битное число)
LENGTH: DW 	0 	; длина TASK в байтах
FILE: 	DW 	0 	; Адрес начала TASK в ОЗУ РК.
BITMAP: DW 	0 	; Адрес начала таблицы BITMAP
CONTROL:DW 	0 	; Адрес старта TASK.
; Загрузка с автоматическим резервированием памяти.
START: 	CALL 	GETMEM 	; Запросить границу ОЗУ у Монитора
	LDA 	TOPS 	; Сравнить, уместится ли "хвост"
	CMP 	L 	; копии при перемешении на целое
	JP 	L10 	; число 256~байтнмх блоков.
	DCR 	H 	; Нет " зарезервировать на блок больше '
L10: 	LDA 	BLOCKS 	; Получить адрес начала области
	CMA 		; перемещения по размеру TASK.
	INR 	A
	ADD 	H
	MOV 	H,A
	MVI 	L,0
	SHLD 	ASTART 	; Сохранить полученное значение
			; для единообразия.
; Загрузка с ручным резервированием памяти.
START1: LHLD 	ASTART 	;
	PUSH 	H 	; Start ADDRES is on stack
	XCHG
	LHLD 	LENGTH 	; Взять размер TASK в (ВС)
	MOV 	B,H
	MOV 	C,L
	LHLD 	FILE 	; Параметры подготовлены;
	XCHG 		; (ВС) длина, (DE) начало TASK,
	PUSH 	B 	; (HL) начало области копии.
; Пересылка 	прикладной 	программы в "верхние" адреса
LOOP: 	MOV 	A,B
	ORA 	C
	JZ 	ENDLOOP
	LDAX 	D
	MOV 	M,A
	INX 	D
	INX 	H
	DCX 	B
	JMP 	LOOP
; Коррекция адресов в копии программы TASK
ENDLOOP:
	POP 	B 	; Длина
	POP 	D 	; Начальный адрес
	PUSH 	D
	LHLD 	BITMAP 	; Взять указатель на таблицу
	PUSH 	H 	; коррекции
	MOV 	H,D
LL10: 	MOV 	A,B 	; Начать коррекцию по таблице
	ORA 	C 	; Все байты скорректированы?
	JZ 	REPORT 	; Да, выход из программы
	DCX 	B 	; Нет, Продолжаем проверку
	MOV 	A,E
	ANI 	7 	; Нужен новый байт на BITMAP?
	JNZ 	LL20 	; Нет, анализируем текущие биты
	XTHL 		; Да, загрузим новый байт с L
	MOV 	A,M
	INX 	H
	XTHL
	MOV 	L,A
LL20: 	MOV 	A,L 	; Обработка текущего байта BITMAP:
	RAL 		; начиная со старшего разряда
	MOV 	L,A 	; (На необходимость коррекции
	JNC 	LL30 	; указывает старший бит. т.е. <f:Y>
	LDAX 	D
	ADD 	H
	STAX 	D
LL30: 	INX	D
	JMP 	LL10
; Выход из загрузчика с печатью сообшения и изменением
; значения верхней границы ОЗУ MAXRAM в Мониторе.
REPORT:	POP 	H
	LXI 	H,STMSG ; 	Отпечатать новое значение
	CALL 	PrintString 	; 	стартового адреса копии TASK
	POP 	H 	;
	CALL 	PUTMEM 	; 	Изменить NAXRAM для "эахлопывания"
	XCHG 		; 	загруженной копии е ОЗУ.
	LHLD 	CONTROL ; 	Изменить адрес перехода по "Б0"
	DAD 	H 	; 	на стартовый адрес копии TASK
	SHLD 	GO_ADR
	MOV 	A,H
	CALL 	PrintHexByte
	MOV 	A,L
	CALL 	PrintHexByte
	LXI 	H,CRLF 	; 	Подготовить HOByte строку для CLI
	CALL 	PrintString
	JMP 	WarmBoot
STMSG: 	DB 	"NEW START ADDRESS:" ,0
CRLF: 	DB 	0DH,0AH,0
	endif

VT52TERMBITMAP:
	include "vt52termbitmap.inc"
BIOSBITMAP:
	include "biosbitmap.inc"
BDOSBITMAP:
	include "bdosbitmap.inc"
CPPBITMAP:
	include "cppbitmap.inc"

HELLO:	DB	1FH, "zagruz~ik CP/M-80 ", VERS/10+'0', '.', VERS#10+'0', 0
MENU:	DB	0dh,0ah,"1. wosstanowitx sistemu na diske", 0dh, 0ah
	DB	"2. sozdatx nowyj pustoj disk", 0dh, 0ah
	DB	"3. ispolxzowatx teku}ij disk", 0dh,0ah
	DB	"=>"
	DB	0
VT52:	DB	1BH, 'Z', 0
VT52PRESENT:
	DB	0dh,0ah, "VT52 najden",0
MONPRESENT:
	DB	0dh,0ah, "ustanowlen redirektor terminala",0
VT52NOTPRESENT:
	DB	0dh,0ah, "ustanowlen |mulqtor VT52",0
NODISKMSG:
	DB	0dh, 0ah, "RAM-disk ne najden", 0dh, 0ah, "navmite <wk> dlq wyhoda w monitor", 0
DISKFOUND:
	DB	0dh, 0ah, "najden RAM-disk", 0
MAXMEM:
	DB	0dh, 0ah, "granica ozu: ",0

RAMSTART:
