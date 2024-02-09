; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80 CP/M 2.2 CH.COM
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

L0103:		DB "CHANGER VERS 1.2", 0Dh, 0Ah, 0Dh, 0Ah, "$"
L0118:		DB "READY TR FOR INPUT, PRESS CR.$"
L0136:		DB "READY TR FOR OUTPUT, PRESS CR.$"
L0155:		DB "READY TR FOR VERIFY, PRESS CR.$"
L0174:		DB "READ ERROR.", 0Dh, 0Ah, "$"
L0182:		DB "VERIFY ERROR.", 0Dh, 0Ah, "$"
L0192:		DB "NO SOURCE FILE PRESENT.", 0Dh, 0Ah, "$"
L01AC:		DB "NOT ENOUGH MEMORY.", 0Dh, 0Ah, "$"
L01C1:		DB "NO DIRECTORY SPACE.", 0Dh, 0Ah, "$"
L01D7:		DB "DISK FULL.", 0Dh, 0Ah, "$"

L01E4:  DB      2Eh             ; '.'
        DB      00h
L01E6:  DB      0E9h
        DB      00h
L01E8:  DB      00h
        DB      00h
        DB      00h

START:  LD      SP,0500h
        LD      DE,L0103
        CALL	WRITESTR
        LD      A,(FCB1+1)	; First filename as argument
        CP      ' '
        JP      NZ,L0209
        LD      DE,L0192
WRITESTREXIT:
	CALL	WRITESTR
	RST	0

L0209:  LD      DE,FCB1
        LD      C,F_OPEN
        CALL    BDOS
        CP      0FFh
        JP      Z,L032D
        LD      HL,0500h
        LD      (L01E4),HL
L021C:  LD      HL,(L01E4)
        EX      DE,HL
        LD      C,F_DMAOFF
        CALL    BDOS
        LD      DE,FCB1
        LD      C,F_READ
        CALL    BDOS
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
        LD      DE,L01AC
        JP	WRITESTREXIT

L024E:  LD      DE,L0136
        CALL	WRITESTR
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
        LD      DE,L0155
        CALL	WRITESTR
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

L02F7:  LD      DE,L0182
        JP	WRITESTREXIT

        ; --- START PROC L0302 ---
L0302:  LD      A,08h
        JP      READER

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
L032D:  LD      DE,L0118
        CALL	WRITESTR
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
L037C:  LD      DE,L0174
        JP	WRITESTREXIT

L0387:  LD      DE,FCB1
        LD      C,F_MAKE
        CALL    BDOS
        CP      0FFh
        JP      NZ,L039F
        LD      DE,L01C1
        JP	WRITESTREXIT

L039F:  LD      HL,0500h
        LD      (L01E4),HL
L03A5:  LD      HL,(L01E4)
        EX      DE,HL
        LD      C,F_DMAOFF
        CALL    BDOS
        LD      DE,FCB1
        LD      C,F_WRITE
        CALL    BDOS
        OR      A
        JP      Z,L03CD
        LD      DE,L01D7
        CALL	WRITESTR
        LD      DE,FCB1
        LD      C,F_DELETE
        CALL    BDOS
	RST	0

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
        LD      DE,FCB1
        LD      C,F_CLOSE
        CALL    BDOS
        RST	0

READER:
	LD	C, A_READ
	JP	BDOS

PUNCHER:
	LD	E, C
	LD	C, A_WRITE
	JP	BDOS

WRITESTR:
	LD	C, C_WRITESTR
	JP	BDOS

READCHAR:
        LD      C, C_READ
        JP	BDOS

