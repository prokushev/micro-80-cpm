; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80 CP/M 2.2 ЗАГРУЗЧИК
; ═══════════════════════════════════════════════════════════════════════
; Является обратным портом ЮТ-88 CP/M 2.2 на МИКРО-80
; todo загрузка в произвольные адреса
; todo автоопределение объема квазидиска
; todo Образ квазидиска теперь содержит полный набор Directory
; todo CH.COM добавлен в образ квазидиска
; todo CP/M размещается в соответствии с верхней границой памяти

	CPU		8080
	Z80SYNTAX	EXCLUSIVE
	
	INCLUDE		"CFG.INC"
	INCLUDE		"syscalls.inc"

	ORG		3100h

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

	; Перемещение CCP/BDOS/BIOS по итоговым адресам
	; (адреса перебираются снизу вверх)
	RST		0
	LD		HL, DISKIMAGE-$
	LD		DE, CCP
	RST		0
	LD		BC, ENDC-$
COPYLOOP:
	LD		A,(HL)
	LD		(DE),A
	INC		HL
	INC		DE
	LD		A,H
	CP		B
	RST		0
	JP		NZ,COPYLOOP-$
	LD		A,L
	CP		C
	RST		0
	JP		NZ,COPYLOOP-$

	; Перемещение эмулятора терминала по итоговым адресам
	
	RST		0
	LD		HL,TERMIMAGE-$
	LD		DE,TERM
L3135:	LD		A,(HL)
	LD		(DE),A
	INC		HL
	INC		DE
	LD		A,H
	CP		DISKIMAGE/0FFh-1	;33h
	RST		0
	JP		NZ,L3135-$

	; Сохранение копии CP/M на квазидиске
	; (адреса перебираются сверху вниз)
	RST		0
	LD		HL, L3120-$
	LD		(Patch1+1-$), HL
	RST		0
	LD		HL,ENDDISK-$
	LD		SP,1C00h
;	Дальше нельзя CALL, RST	
	LD		A,0FEh
	OUT		(40h),A			; Подключаем первые 64кб RAMDISKа

L3120:	LD		D,(HL)
	DEC		HL
	LD		E,(HL)
	DEC		HL
	PUSH		DE
	LD		A,H
	CP		DISKIMAGE/0FFh-1	;33h
Patch1:
	JP		NZ,L3120

	LD		A,0FFh
	OUT		(40h),A			; Отключаем RAMDISK
;	Дальше можно CALL, RST	

	JP		BIOS

; ───────────────────────────────────────────────────────────────────────
; Подпрограмма модификации относительного адреса перехода
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

	ORG		31E0H
TERMIMAGE:
	BINCLUDE	CPM64-TERM.BIN

	; Образ квазидиска - системная часть
	ORG		3400H
DISKIMAGE:
	BINCLUDE	CPM64-CCP.BIN
	ORG		3400H+800H
	BINCLUDE	CPM64-BDOS.BIN
	ORG		3400H+1600H
	BINCLUDE	CPM64-BIOS.BIN
ENDC	EQU		$

	; Продолжение образа квазидиска - директория и данные
	; @TODO Разместить тут начальный каталог + CH.COM, как минимум
	DB		5000H-$ DUP (0E5H)
ENDDISK	EQU	$-1
