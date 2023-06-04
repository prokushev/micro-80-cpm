; Эмулятор терминала VT-52 для МИКРО-80 CP/M 2.2
; Обратный порт с ЮТ-88
; Оптимизация по размеру
; Убран прямой переход (не через точку входа) в МОНИТОР
; todo Убрано использование системных переменных (Для МОНИТОРов, поддерживающих получение координат курсора)
;
; Для МИКРО-80 (Стандартный МОНИТОР) и ЮТ-88 (МОНИТОР-F) используется системная переменная EK_ADR = 0F75AH,
; т.к. нет никакого способа получить значение координат курсора. МОНИТОР для МИКРО-80, совместимный с Радио-86РК,
; работать с данным эмулятором терминала не будет.
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
; Z			ident					Identify what the terminal is, see notes below.
; =			Alternate keypad		Changes the character codes returned by the keypad.
; >			Exit alternate keypad	Changes the character codes returned by the keypad. 
;
; Таблица дополнительных поддерживаемых кодов
;
; +E		Clear screen			Clear whole screen GEMDOS/TOS extension

		CPU			8080
		Z80SYNTAX	EXCLUSIVE

		INCLUDE		CFG.INC

		ORG			TERM

EK_ADR	EQU			0F75AH		;  Текущий адрес экрана в позиции курсора

		; Entry Point
		; --- START PROC TERM ---
		PUSH		HL
		PUSH		BC
		PUSH		DE
		PUSH		AF
		LD			A,(EscSequenceState)
		OR			A				; CP 00h
		JP			NZ,ProcessEscSequence
		LD			HL, PrintCAndExit
		PUSH		HL
		LD			A,C
		CP			20h             ; ' '
		;JP			NC,PrintCAndExit
		RET			NC
		CP			08h
		;JP			Z,PrintCAndExit
		RET			Z
		CP			0Ah
		;JP			Z,PrintCAndExit
		RET			Z
		CP			0Dh
		;JP			Z,PrintCAndExit
		RET			Z
		POP			HL
		CP			1Bh
		JP			NZ,ExitTerm
		LD			A,01h
		LD			(EscSequenceState),A

		; --- START PROC ExitTerm ---
ExitTerm:
		POP			AF
		POP			DE
		POP			BC
		POP			HL
		RET

ProcessEscSequence:
		LD			A,(EscSequenceState)
		CP			01h
		JP			NZ,LF5B9
		LD			A,C
		CP			41h             ; 'A' Cursor up
		JP			NZ,LF543
		LD			C,19h
EndEscSeqPrintCAndExit:
		XOR			A				; LD      A,00h
		LD			(EscSequenceState),A
PrintCAndExit:
		; JP      0FC47h			; todo Прямой вызов МОНИТОРА
		CALL		0F809H
		JP			ExitTerm

LF543:	LD			HL, EndEscSeqPrintCAndExit
		PUSH		HL
		CP			42h             ; 'B' Cursor down
;		JP			NZ,LF54D
		LD			C,1Ah
;		JP			EndEscSeqPrintCAndExit
		;JP			Z, EndEscSeqPrintCAndExit
		RET			Z

LF54D:	CP			43h             ; 'C' Cursor right
;		JP			NZ,LF557
		LD			C,18h
		;JP			Z, EndEscSeqPrintCAndExit
		RET			Z

LF557:	CP			44h             ; 'D' Cursor left
;		JP			NZ,LF561
		LD			C,08h
		;JP			Z, EndEscSeqPrintCAndExit
		RET			Z

LF561:	CP			45h             ; 'E' Clear Screen - расширение с Atari
;		JP			NZ,LF56B
		LD			C,1Fh
		;JP			Z, EndEscSeqPrintCAndExit
		RET			Z

LF56B:	CP			48h             ; 'H' Cursor home
;		JP			NZ,LF575
		LD			C,0Ch
		;JP			Z, EndEscSeqPrintCAndExit
		RET			Z

		POP			HL

LF575:	CP			4Ah             ; 'J' Clear to end of screen
		JP			NZ,LF58A
		LD			HL,(EK_ADR)
		LD			A,0F0h
		LD			B,20h           ; ' '
LF581:	LD			(HL),B
		INC			HL
		CP			H
		JP			NZ,LF581
		JP			ExitEscSequence

LF58A:	CP			4Bh             ; 'K' Clear to end of line
		JP			NZ,LF5A3
		LD			HL,(EK_ADR)
;		XOR			A				; Это зачем?
		LD			A,L
		AND			0C0h
		ADD			A,40h           ; '@'
		LD			B,20h           ; ' '
LF59A:	LD			(HL),B
		INC			HL
		CP			L
		JP			NZ,LF59A
		JP			ExitEscSequence

LF5A3:	CP			59h             ; 'Y' Move cursor to position
		JP			NZ,ExitEscSequence
		LD			HL,(EK_ADR)
		LD			DE,0F801h		; -7FFH
		ADD			HL,DE
		LD			(HL),00h
		LD			A,02h
		LD			(EscSequenceState),A
		JP			ExitTerm

LF5B9:	LD			A,C
		CP			1Bh
		JP			NZ,LF5C9
		LD			A,01h
		LD			(EscSequenceState),A
		LD			C,1Fh
		JP			PrintCAndExit

LF5C9:	LD			A,(EscSequenceState)
		CP			02h
		JP			NZ,LF5E0
		XOR			A
		LD			A,C
		SBC			A,20h           ; ' '
		LD			(LF616),A
		LD			A,03h
		LD			(EscSequenceState),A
		JP			ExitTerm

LF5E0:	XOR			A
		LD			A,C
		SBC			A,20h           ; ' '
		CP			3Fh             ; '?'
		JP			C,LF5EB
		LD			A,3Fh           ; '?'
LF5EB:	LD			L,A
		LD			A,(LF616)
		RRCA
		RRCA
		LD			C,A
		AND			0C0h
		OR			L
		LD			L,A
		LD			A,C
		AND			07h
		OR			0E8h
		LD			H,A
		LD			(EK_ADR),HL
		LD			DE,0F801h		; -07FFH
		ADD			HL,DE
		LD			(HL),80h

		; --- START PROC ExitEscSequence ---
ExitEscSequence:
		XOR			A				; LD      A,00h
		LD			(EscSequenceState),A
		JP			ExitTerm

EscSequenceState:
		DB			00h
LF616:	DB			00h

