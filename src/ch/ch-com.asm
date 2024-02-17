; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80/ЮТ-88 CP/M 2.2 CH.COM
; ═══════════════════════════════════════════════════════════════════════
; + Обратный порт с ЮТ-88 CP/M 2.2 BIOS на МИКРО-80
; + Отвязан от МОНИТОРа (замена вызовов МОНИТОРа tape in/tape out на функции punch/reader BDOS)
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

L01E4:  DB      2Eh             ; '.'
        DB      00h
L01E6:  DB      0E9h
        DB      00h
L01E8:  DB      00h
        DB      00h
        DB      00h

START:  LD      SP,0500h
        LD      E,L0103 & 0FFH
        CALL	WRITESTRID
        LD      A,(FCB1+1)	; First filename as argument
        CP      ' '
        JP      NZ,PROCESS
        LD      E,L0192 & 0FFH
WRITESTRIDEXIT:
	CALL	WRITESTRID
	RST	0

PROCESS:
	LD      C,F_OPEN
        CALL    F_BDOS
        CP      0FFh
        JP      Z,L032D
        LD      HL,0500h
        LD      (L01E4),HL
L021C:  LD      HL,(L01E4)
        EX      DE,HL
        LD      C,F_DMAOFF
        CALL    BDOS
        LD      C,F_READ
        CALL    F_BDOS
        OR      A
        JP      NZ,L024E
        LD      HL,(L01E4)
        LD      DE,0080h
        ADD     HL,DE
        LD      (L01E4),HL
        LD      A,H
        LD      HL,(0006h)
        CP      H
        JP      C,L021C
        LD      E,L01AC & 0FFH
        JP	WRITESTRIDEXIT

L024E:  LD      E,L0136 & 0FFH
        CALL	WRITESTRID
        CALL	READCHAR
        CALL    CRLF
        LD      DE,0500h
        LD      HL,(L01E4)
        CALL    L0307
        LD      (L01E6),HL
        LD      HL,(L01E4)
        LD      DE,0500h
        LD      A,L
        SUB     E
        LD      L,A
        LD      A,H
        SBC     A,D
        LD      H,A
        LD      (L01E8),HL
; Запись в формате МИКРО-80/ЮТ-88
        LD      L,00h
L027B:  LD      C,00h
        CALL    PUNCHER
        DEC     L
        JP      NZ,L027B
        LD      C,0E6h
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
        LD      HL,0500h
L02A3:  LD      C,(HL)
        CALL    PUNCHER
        INC     HL
        DEC     DE
        LD      A,D
        OR      E
        JP      NZ,L02A3
        LD      E,L0155 & 0FFH
        CALL	WRITESTRID
        CALL	READCHAR
        CALL    CRLF
        LD      HL,(L01E6)
        LD      A,0FFh
        CALL    READER
        CP      L
        JP      NZ,L02F7
        CALL    L0302
        CP      H
        JP      NZ,L02F7
        LD      HL,(L01E8)
        CALL    L0302
        CP      L
        JP      NZ,L02F7
        CALL    L0302
        CP      H
        JP      NZ,L02F7
        EX      DE,HL
        LD      HL,0500h
L02E6:  CALL    L0302
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

        ; --- START PROC L032D ---
L032D:  LD      E,L0118 & 0FFH
        CALL	WRITESTRID
        CALL	READCHAR
        CALL    CRLF
        LD      A,0FFh
        CALL    READER
        LD      L,A
        CALL    L0302
        LD      H,A
        LD      (L01E6),HL
        CALL    L0302
        LD      L,A
        CALL    L0302
        LD      H,A
        LD      (L01E8),HL
        EX      DE,HL
        LD      HL,0500h
L0359:  CALL    L0302
        LD      (HL),A
        INC     HL
        DEC     DE
        LD      A,D
        OR      E
        JP      NZ,L0359
        LD      HL,(L01E8)
        LD      DE,0500h
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

L039F:  LD      HL,0500h
        LD      (L01E4),HL
L03A5:  LD      HL,(L01E4)
        EX      DE,HL
        LD      C,F_DMAOFF
        CALL    BDOS
        LD      C,F_WRITE
        CALL    F_BDOS
        OR      A
        JP      Z,L03CD
        LD      E,L01D7 & 0FFH
        CALL	WRITESTRID
        LD      C,F_DELETE
        JP	F_BDOS_EXIT

L03CD:  LD      HL,(L01E4)
        LD      DE,0080h
        ADD     HL,DE
        LD      (L01E4),HL
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
	LD	D, (L0103 & 0FF00H) >> 8
WRITESTR:
	LD	C, C_WRITESTR
	JP	BDOS

READCHAR:
        LD      C, C_READ
        JP	BDOS

