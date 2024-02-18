; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80/ЮТ-88 CP/M 2.2 CH.COM Программа обмена файлов с лентой
; ═══════════════════════════════════════════════════════════════════════
; + Обратный порт с ЮТ-88 CP/M 2.2 BIOS на МИКРО-80
; todo Отвязан от МОНИТОРа (замена вызовов МОНИТОРа tape in/tape out на функции punch/reader BDOS)
; + Некоторая оптимизация по размеру
; todo Поддержка формата записи, отличной от ЮТ-88/МИКРО-80

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
F_DELETE	EQU		13H
F_READ		EQU		14H
F_WRITE		EQU		15H
F_MAKE		EQU		16H
F_DMAOFF	EQU		1AH

		JP      START

		INCLUDE	"en.inc"
;		INCLUDE	"ru.inc"
		INCLUDE	"syscalls.inc"

STACK		EQU 500H
FILESTART	EQU 500H

FILEEND:
	DW      0
CHKSUM:	DW	0
FILELEN:
	DW      0
        DB      00h
        DB      00h

START: 	LD      SP, STACK
        LD      E,HELLO & 0FFH
        CALL	WRITESTRID		; Выводим сообщение
        LD      A,(FCB1+1)		; Проверяем аргумент
        CP      ' '
        JP      NZ,PROCESS
        LD      E,NOFILE & 0FFH
WRITESTRIDEXIT:
	CALL	WRITESTRID		; Выводим сообщение
	RST	0			; Возврат в CP/M

PROCESS:
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
        JP	WRITESTRIDEXIT

L024E:  LD      E,L0136 & 0FFH
	CALL	WRITESTRIDREADCHAR
        LD      DE,FILESTART
        LD      HL,(FILEEND)
        CALL    CALCCHKSUM		; Подсчет КС
        LD      (CHKSUM),HL
        LD      HL,(FILEEND)
        LD      DE,FILESTART
        LD      A,L
        SUB     E
        LD      L,A
        LD      A,H
        SBC     A,D
        LD      H,A
        LD      (FILELEN),HL
;
; Запись в формате:
; КС     2 байта
; Длина  2 байта
; Данные <длина> байт
;
        LD      L,00h
L027B:  LD      C,00h			; пишем пилот-тон
        CALL    PUNCHER
        DEC     L
        JP      NZ,L027B
        LD      C,0E6h			; пишем синхробайт
        CALL    PUNCHER
        LD      HL,(CHKSUM)
        LD      C,L
        CALL    PUNCHER
        LD      C,H
        CALL    PUNCHER
        LD      HL,(FILELEN)
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
	CALL	WRITESTRIDREADCHAR
        LD      HL,(CHKSUM)
        LD      A,0FFh			; С поиском синхробайта
        CALL    READER
        CP      L
        JP      NZ,L02F7
        CALL    L0302			; Чтение без синхробайта
        CP      H
        JP      NZ,L02F7
        LD      HL,(FILELEN)
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

        ; --- START PROC CALCCHKSUM ---
CALCCHKSUM:
	LD	BC,0000h
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

        ; --- START PROC LOADFILE ---
LOADFILE:
	LD      E,READYLOAD & 0FFH
	CALL	WRITESTRIDREADCHAR
        LD      A,0FFh			; Ожидаем синхробайт
        CALL    READER
        LD      L,A
        CALL    L0302			; Чтение без синхробайта
        LD      H,A
        LD      (CHKSUM),HL
        CALL    L0302			; Чтение без синхробайта
        LD      L,A
        CALL    L0302			; Чтение без синхробайта
        LD      H,A
        LD      (FILELEN),HL
        EX      DE,HL
        LD      HL,FILESTART
L0359:  CALL    L0302			; Чтение без синхробайта
        LD      (HL),A
        INC     HL
        DEC     DE
        LD      A,D
        OR      E
        JP      NZ,L0359
        LD      HL,(FILELEN)
        LD      DE,FILESTART
        ADD     HL,DE
        CALL    CALCCHKSUM		; Подсчет КС
        EX      DE,HL
        LD      HL,(CHKSUM)
        LD      A,D
        CP      H
        JP      NZ,READERROR
        LD      A,E
        CP      L
        JP      Z,L0387
READERROR:
	LD	E,MSG_READERROR & 0FFH
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
        LD      HL,(FILELEN)
        LD      A,L
        SUB     80h
        LD      L,A
        LD      A,H
        SBC     A,00h
        LD      H,A
        LD      (FILELEN),HL
        OR      L
        JP      NZ,L03A5
        LD      C,F_CLOSE
F_BDOS_EXIT:
	CALL    F_BDOS
        RST	0

F_BDOS:
        LD      DE,FCB1
        JP	BDOS

WRITESTRIDREADCHAR:
        CALL	WRITESTRID		; Выводим сообщение
        CALL	READCHAR
        ; --- START PROC CRLF ---
CRLF:	LD      E,0DH
	CALL	WRITECHAR
        LD      E,0AH
	JP	WRITECHAR

        ; --- START PROC L0302 ---
L0302:  LD      A,08h
READER:	JP	TapeReadByte

PUNCHER:
	JP	TapeWriteByte

WRITESTRID:
	LD	D, (HELLO & 0FF00H) >> 8
WRITESTR:
	LD	C, C_WRITESTR
	DB	3AH	;LD	A,(word)
WRITECHAR:
	LD      C,C_WRITE
	DB	3AH	;LD	A,(word)
READCHAR:
        LD      C, C_READ
        JP	BDOS

