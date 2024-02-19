; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80/ЮТ-88 CP/M 2.2 CHDISK.COM Программа копии диска на ленту
; ═══════════════════════════════════════════════════════════════════════
; Программа написана по оаисанию в статье МПСиС. Опубликованой программы
; не найдено.

		CPU		8080
		Z80SYNTAX	EXCLUSIVE

		ORG		0100h

BDOS		EQU		0005H

FCB1		EQU		005CH

C_READ		EQU		01H
C_WRITE		EQU		02H
A_READ		EQU		03H
A_WRITE		EQU		04H
C_WRITESTR	EQU		09H
C_READSTR	EQU		0AH
DRV_ALLRESET	EQU		0DH
F_OPEN		EQU		0FH
F_CLOSE		EQU		10H
F_SFIRST	EQU		11H
F_SNEXT		EQU		12H
F_DELETE	EQU		13H
F_READ		EQU		14H
F_WRITE		EQU		15H
F_MAKE		EQU		16H
F_DMAOFF	EQU		1AH

		JP      START

		INCLUDE	"en.inc"
;		INCLUDE	"ru.inc"

STACK		EQU 500H
FILESTART	EQU 500H
FILEEND:
	DW      0
L01E6: 	DB      0E9h
        DB      00h
L01E8: 	DB      00h
        DB      00h
        DB      00h
MASK:	DB	0, "???????????",24 DUP (0)

START: 	LD      SP, STACK
        LD      E,HELLO & 0FFH
        CALL	WRITESTRID		; Выводим сообщение

PROCESS:
	LD	DE, MASK
	LD	C,F_SFIRST		; Ищем все файлы
        CALL    BDOS

	LD	HL, MASK
	LD	B, 11
PRFILE:	
	LD	E, (HL)
	LD	C, C_WRITE
        CALL    BDOS
	INC	HL
	DEC	B
	JP	NZ, PRFILE

;	CALL	SAVEFILE
	LD	DE, MASK
	LD	C,F_SNEXT
        CALL    BDOS
	RST	0

	LD      C,F_OPEN
        CALL    F_BDOS
        CP      0FFh			; Файл не найден
        JP      Z,LOADFILE
        LD      HL,FILESTART		; начальный адрес загрузки
        LD      (FILEEND),HL
L021C:  LD      HL,(FILEEND)		
        EX      DE,HL
        LD      C,F_DMAOFF
        CALL    BDOS
        LD      C,F_READ
        CALL    F_BDOS
        OR      A
        JP      NZ,L024E
        LD      HL,(FILEEND)
        LD      DE,0080h
        ADD     HL,DE
        LD      (FILEEND),HL
        LD      A,H
        LD      HL,(0006h)
        CP      H
        JP      C,L021C
        LD      E,L01AC & 0FFH
WRITESTRIDEXIT:
        CALL	WRITESTRID		; Выводим сообщение
	RST	0

L024E:  LD      E,L0136 & 0FFH
        CALL	WRITESTRID		; Выводим сообщение
        CALL	READCHAR
        CALL    CRLF
        LD      DE,FILESTART
        LD      HL,(FILEEND)
        CALL    L0307			;
        LD      (L01E6),HL
        LD      HL,(FILEEND)
        LD      DE,FILESTART
        LD      A,L
        SUB     E
        LD      L,A
        LD      A,H
        SBC     A,D
        LD      H,A
        LD      (L01E8),HL
; Запись в формате МИКРО-80/ЮТ-88
        LD      L,00h
L027B:  LD      C,00h			; пишем пилот-тон
        CALL    PUNCHER
        DEC     L
        JP      NZ,L027B
        LD      C,0E6h			; пишем синхробайт
        CALL    PUNCHER
        LD      HL,(L01E6)
        LD      C,L
        CALL    PUNCHER
        LD      C,H
        CALL    PUNCHER
        LD      HL,(L01E8)
        LD      C,L
        CALL    PUNCHER
        LD      C,H
        CALL    PUNCHER
        EX      DE,HL
        LD      HL,FILESTART
L02A3:  LD      C,(HL)			; Сохраняем байты
        CALL    PUNCHER
        INC     HL
        DEC     DE
        LD      A,D
        OR      E
        JP      NZ,L02A3
        LD      E,L0155 & 0FFH
        CALL	WRITESTRID		; Выводим сообщение
        CALL	READCHAR
        CALL    CRLF
        LD      HL,(L01E6)
        LD      A,0FFh			; С поиском синхробайта
        CALL    READER
        CP      L
        JP      NZ,L02F7
        CALL    L0302			; Чтение без синхробайта
        CP      H
        JP      NZ,L02F7
        LD      HL,(L01E8)
        CALL    L0302			; Чтение без синхробайта
        CP      L
        JP      NZ,L02F7
        CALL    L0302			; Чтение без синхробайта
        CP      H
        JP      NZ,L02F7
        EX      DE,HL
        LD      HL,FILESTART
L02E6:  CALL    L0302			; Чтение без синхробайта
        CP      (HL)
        JP      NZ,L02F7
        INC     HL
        DEC     DE
        LD      A,D
        OR      E
        JP      NZ,L02E6
	RST	0

L02F7:  LD      E,L0182 & 0FFH
        JP	WRITESTRIDEXIT

        ; --- START PROC L0307 ---
L0307:  LD      BC,0000h
L030A:  LD      A,(DE)
        ADD     A,C
        LD      C,A
        LD      A,00h
        ADC     A,B
        LD      B,A
        INC     DE
        LD      A,D
        CP      H
        JP      NZ,L030A
        LD      A,E
        CP      L
        JP      NZ,L030A
        LD      L,C
        LD      H,B
        RET

        ; --- START PROC CRLF ---
CRLF:	LD      C,C_WRITE
        LD      E,0DH
        CALL    BDOS
        LD      C,C_WRITE
        LD      E,0AH
        JP      BDOS

        ; --- START PROC LOADFILE ---
LOADFILE:
	LD      E,READYLOAD & 0FFH
        CALL	WRITESTRID		; Выводим сообщение
        CALL	READCHAR
        CALL    CRLF
        LD      A,0FFh			; Ожидаем синхробайт
        CALL    READER
        LD      L,A
        CALL    L0302			; Чтение без синхробайта
        LD      H,A
        LD      (L01E6),HL
        CALL    L0302			; Чтение без синхробайта
        LD      L,A
        CALL    L0302			; Чтение без синхробайта
        LD      H,A
        LD      (L01E8),HL
        EX      DE,HL
        LD      HL,FILESTART
L0359:  CALL    L0302			; Чтение без синхробайта
        LD      (HL),A
        INC     HL
        DEC     DE
        LD      A,D
        OR      E
        JP      NZ,L0359
        LD      HL,(L01E8)
        LD      DE,FILESTART
        ADD     HL,DE
        CALL    L0307
        EX      DE,HL
        LD      HL,(L01E6)
        LD      A,D
        CP      H
        JP      NZ,L037C
        LD      A,E
        CP      L
        JP      Z,L0387
L037C:  LD      E,L0174 & 0FFH
        JP	WRITESTRIDEXIT

L0387:  LD      C,F_MAKE
        CALL    F_BDOS
        CP      0FFh
        JP      NZ,L039F
        LD      E,L01C1 & 0FFH
        JP	WRITESTRIDEXIT

L039F:  LD      HL,FILESTART
        LD      (FILEEND),HL
L03A5:  LD      HL,(FILEEND)
        EX      DE,HL
        LD      C,F_DMAOFF
        CALL    BDOS
        LD      C,F_WRITE
        CALL    F_BDOS
        OR      A
        JP      Z,L03CD
        LD      E,L01D7 & 0FFH
        CALL	WRITESTRID		; Выводим сообщение
        LD      C,F_DELETE
        JP	F_BDOS_EXIT

L03CD:  LD      HL,(FILEEND)
        LD      DE,0080h
        ADD     HL,DE
        LD      (FILEEND),HL
        LD      HL,(L01E8)
        LD      A,L
        SUB     80h
        LD      L,A
        LD      A,H
        SBC     A,00h
        LD      H,A
        LD      (L01E8),HL
        OR      L
        JP      NZ,L03A5
        LD      C,F_CLOSE
F_BDOS_EXIT:
	CALL    F_BDOS
        RST	0

F_BDOS:
        LD      DE,FCB1
        JP	BDOS

        ; --- START PROC L0302 ---
L0302:  LD      A,08h
READER:	LD	C, A_READ
	JP	BDOS

PUNCHER:
	LD	E, C
	LD	C, A_WRITE
	JP	BDOS

WRITESTRID:
	LD	D, (HELLO & 0FF00H) >> 8
WRITESTR:
	LD	C, C_WRITESTR
	JP	BDOS

READCHAR:
        LD      C, C_READ
        JP	BDOS

