; ═══════════════════════════════════════════════════════════════════════
; Эмулятор терминала VT-52 для МИКРО-80/ЮТ-88 CP/M 2.2
; ═══════════════════════════════════════════════════════════════════════
; + Обратный порт с ЮТ-88
; + Оптимизация по размеру
; + Убран прямой переход (не через точку входа) в МОНИТОР
; todo Расширена поддержка VT-52 (из моего МОНИТОРА РК86)
; todo Поддержка РК-86 (для этого нужен позиционно независимый код)
; todo Отслеживание позиции курсора. Теперь не зависит от рабочих ячеек МОНИТОРа.
; Для МИКРО-80 (Стандартный МОНИТОР и М/80К) и ЮТ-88 (МОНИТОР-F) 
; используется системная переменная EK_ADR = 0F75AH
; todo Эмуляция графических символов (использование +-! и т.п.)
;
; Таблица поддерживаемых кодов (+ означает наличие поддержки)
;
; Code		Name					Meaning
; +A		Cursor up 				Move cursor one line upwards.
; 									Does not cause scrolling when it reaches the top.
; +B		Cursor down 			Move cursor one line downwards.
; +C		Cursor right 			Move cursor one column to the right.
; +D		Cursor left 			Move cursor one column to the left.
; F			Enter graphics mode		Use special graphics character set, VT52 and later.
; G			Exit graphics mode		Use normal US/UK character set
; +H		Cursor home 			Move cursor to the upper left corner.
; I			Reverse line feed 		Insert a line above the cursor, then move the cursor into it.
; 									May cause a reverse scroll if the cursor was on the first line.
; +J		Clear to end of screen 	Clear screen from cursor onwards.
; +K		Clear to end of line 	Clear line from cursor onwards.
; L			Insert line 			Insert a line.
; M			Delete line 			Remove line.
; +Yrc		Set cursor position		Move cursor to position c,r, encoded as single characters.
; 									The VT50H also added the "SO" command that worked identically,
; 									providing backward compatibility with the VT05.
; +Z			ident					Identify what the terminal is, see notes below.
; =			Alternate keypad		Changes the character codes returned by the keypad.
; >			Exit alternate keypad	Changes the character codes returned by the keypad. 
;
; Таблица дополнительных поддерживаемых кодов
;
; +E	Clear screen			Clear whole screen GEMDOS/TOS extension

	CPU		8080
	Z80SYNTAX	EXCLUSIVE

	INCLUDE	CFG.INC

	ORG	TERM_ADDR

	JP	VT52_CO		; 0 Печать символа на экрат
	JP	VT52_CI		; 3 Ввод символа с клавиатуры
	JP	VT52_CST	; 6 Состояние клавиатуры
	JP	VT52_MSG	; 9 Печать ASCIIZ строки

VT52_CST:
	LD	A, (IDENT)
	OR	A
	LD	A, 0
	RET	NZ
	JP	0F812H

VT52_CI:
	PUSH	HL
	LD	HL, IDENT
	LD	A, 1BH
	CP	(HL)
	JP	Z, VT52_CI1
	LD	A, '/'
	CP	(HL)
	JP	Z, VT52_CI2
	LD	A, 'K'
	CP	(HL)
	JP	Z, VT52_CI3
	POP	HL
	JP	0F803H

VT52_CI1:
	LD	(HL), '/'
	POP	HL
	RET
VT52_CI2:
	LD	(HL), 'K'
	POP	HL
	RET
VT52_CI3:
	LD	(HL), 0
	POP	HL
	RET

VT52_MSG:
	LD      A,(HL)
        AND     A
        RET     Z
	PUSH	BC
	LD	C, A
        CALL    TERM_ADDR
	POP	BC
        INC     HL
        JP      VT52_MSG

; Данная переменная одинакова для МОНИТОР и M/80K
EK_ADR	EQU	0F75AH		;  Текущий адрес экрана в позиции курсора

VT52_CO:
	PUSH	HL
	PUSH	BC
	PUSH	DE
	PUSH	AF
	LD	A,(EscSequenceState)
	OR	A				; CP 00h
	JP	NZ, ProcessEscSequence

	LD	HL, PrintCAndExit	; Кладем в стек адрес возврата из эмулятора терминала
	PUSH	HL

	LD	A,C		
	CP	' '             ; ' '
	RET	NC		;JP NC,PrintCAndExit
	CP	08h
	RET	Z		;JP Z,PrintCAndExit
	CP	0Ah
	RET	Z		;JP Z,PrintCAndExit
	CP	0Dh
	RET	Z		;JP Z,PrintCAndExit
	CP	1Fh
	RET	Z		;JP Z,PrintCAndExit
	POP	HL
	CP	1Bh
	JP	NZ,ExitTerm
	LD	A,01h
	LD	(EscSequenceState),A

ExitTerm:
	POP	AF
	POP	DE
	POP	BC
	POP	HL
	RET
	
ProcessEscSequence:
	LD	A,(EscSequenceState)
	CP	01h
	JP	NZ,LF5B9
	LD	DE, EndEscSeqPrintCAndExit
	PUSH	DE
	LD	A,C
	CP	'A'             ; 'A' Cursor up
;	JP	NZ,LF543
	LD	C,19h
	RET	Z

LF543:	CP	'B'             ; 'B' Cursor down
;		JP			NZ,LF54D
	LD	C,1Ah
;		JP			EndEscSeqPrintCAndExit
		;JP			Z, EndEscSeqPrintCAndExit
	RET	Z
LF54D:	CP	'C'             ; 'C' Cursor right
;		JP			NZ,LF557
	LD	C,18h
		;JP			Z, EndEscSeqPrintCAndExit
	RET	Z

LF557:	CP	'D'             ; 'D' Cursor left
;		JP			NZ,LF561
	LD	C,08h
		;JP			Z, EndEscSeqPrintCAndExit
	RET	Z

LF561:	CP	'E'             ; 'E' Clear Screen - расширение с Atari
;		JP			NZ,LF56B
	LD	C,1Fh
		;JP			Z, EndEscSeqPrintCAndExit
	RET	Z

LF56B:	CP	'H'             ; 'H' Cursor home
;		JP			NZ,LF575
	LD	C,0Ch
		;JP			Z, EndEscSeqPrintCAndExit
	RET	Z
	POP	HL
	LD	C, A		; Восстанавливаем C

LF575:	CP	'J'             ; 'J' Clear to end of screen
	JP	NZ,LF58A
	LD	HL,(EK_ADR)
	LD	A,0F0h
	LD	B,' '           ; ' '
LF581:	LD	(HL),B
	INC	HL
	CP	H
	JP	NZ,LF581
	JP	ExitEscSequence

LF58A:	CP	'K'             ; 'K' Clear to end of line
	JP	NZ,ESC_Y
	LD	HL,(EK_ADR)
	LD	A,L
	AND	0C0h
	ADD	A,40h           ; '@'
	LD	B,' '           ; ' '
LF59A:	LD	(HL),B
	INC	HL
	CP	L
	JP	NZ,LF59A
	JP	ExitEscSequence

ESC_Y:	CP	'Y'             ; 'Y' Move cursor to position
	JP	NZ,ESC_Z

	; --- Гашение текушего курсора
	LD	HL,(EK_ADR)
	LD	DE,0F801h		; -7FFH
	ADD	HL,DE
	LD	(HL),00h
	; -----
	LD	A,02h
	LD	(EscSequenceState),A
	JP	ExitTerm

ESC_Z:	CP	'Z'
	JP	NZ, ESC_SL
	LD	A, 1BH
	LD	(IDENT), A
	JP	ExitEscSequence

ESC_SL:
	CP	'/'
	JP	Z, ExitEscSequence

EndEscSeqPrintCAndExit:
	XOR	A
	LD	(EscSequenceState),A

PrintCAndExit:
	CALL	0F809H
	JP	ExitTerm

LF5B9:	LD	A,C
	CP	1Bh
	JP	NZ,LF5C9
	LD	A,01h
	LD	(EscSequenceState),A
	LD	C,1Fh
	JP	PrintCAndExit

LF5C9:	LD	A,(EscSequenceState)
	CP	02h
	JP	NZ,LF5E0
		
	XOR	A
	LD	A,C
	SBC	A,20h           ; ' '
	LD	(LF616),A
	LD	A,03h
	
	LD	(EscSequenceState),A
	JP	ExitTerm

LF5E0:	XOR	A
	LD	A,C
	SBC	A,20h           ; ' '
	CP	3Fh             ; '?'
	JP	C,LF5EB
	LD	A,3Fh           ; '?'
LF5EB:	LD	L,A
	LD	A,(LF616)
	RRCA
	RRCA
	LD	C,A
	AND	0C0h
	OR	L
	LD	L,A
	LD	A,C
	AND	07h
	OR	0E8h
	LD	H,A

	; --- Новая позиция курсора
	LD	(EK_ADR),HL
	LD	DE,0F801h		; -07FFH
	ADD	HL,DE
	LD	(HL),80h

ExitEscSequence:
	XOR	A
	LD	(EscSequenceState),A
	JP	ExitTerm

IDENT:	DB	00h
EscSequenceState:
	DB	00h
LF616:	DB	00h

