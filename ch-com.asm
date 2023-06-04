; МИКРО-80 CP/M 2.2 CH.COM
; Является обратным портом ЮТ-88 CP/M 2.2 BIOS на МИКРО-80
;
; todo Отвязать от МОНИТОРа (замена вызовов МОНИТОРа tape in/tape out на функции punch/reader BDOS)
; todo Оптимизация по размеру

		CPU			8080
		Z80SYNTAX	EXCLUSIVE

		ORG			0100h

BDOS	EQU			0005H

C_READ		EQU		01H
C_WRITESTR	EQU		09H

		JP      START

L0103:  DB      "CHANGER VERS 1.1", 0Dh, 0Ah, 0Dh, 0Ah, "$"
		DB		"READY TR FOR INPUT, PRESS CR.$"
		DB		"READY TR FOR OUTPUT, PRESS CR.$"
		DB		"READY TR FOR VERIFY, PRESS CR.$"
		DB		"READ ERROR.", 0Dh, 0Ah, "$"
		DB		"VERIFY ERROR.", 0Dh, 0Ah, "$"
		DB		"NO SOURCE FILE PRESENT.", 0Dh, 0Ah, "$"
		DB		"NOT ENOUGH MEMORY.", 0Dh, 0Ah, "$"
		DB		"NO DIRECTORY SPACE.", 0Dh, 0Ah, "$"
		DB		"DISK FULL.", 0Dh, 0Ah, "$"

L01E4:  DB      2Eh             ; '.'
        DB      00h
L01E6:  DB      0E9h
        DB      00h
L01E8:  DB      00h
        DB      00h
        DB      00h

START:  LD      SP,0500h
        LD      DE,0103h
        CALL	WRITESTR
        LD      A,(005Dh)
        CP      20h             ; ' '
        JP      NZ,L0209
        LD      DE,0192h
WRITESTREXIT:
		CALL	WRITESTR
		RST		0

L0209:  LD      DE,005Ch
        LD      C,0Fh
        CALL    BDOS
        CP      0FFh
        JP      Z,L032D
        LD      HL,0500h
        LD      (L01E4),HL
L021C:  LD      HL,(L01E4)
        EX      DE,HL
        LD      C,1Ah
        CALL    BDOS
        LD      DE,005Ch
        LD      C,14h
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
        LD      DE,01ACh
        JP		WRITESTREXIT

L024E:  LD      DE,0136h
        CALL	WRITESTR
        CALL	READCHAR
        CALL    L031F
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
        LD      DE,0155h
        CALL	WRITESTR
        CALL	READCHAR
        CALL    L031F
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
        ;JP      0000h
		RST		0

L02F7:  LD      DE,0182h
        JP		WRITESTREXIT

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

        ; --- START PROC L031F ---
L031F:  LD      C,02h
        LD      E,0Dh
        CALL    BDOS
        LD      C,02h
        LD      E,0Ah
        JP      BDOS

        ; --- START PROC L032D ---
L032D:  LD      DE,0118h
        CALL	WRITESTR
        CALL	READCHAR
        CALL    L031F
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
L037C:  LD      DE,0174h
        JP		WRITESTREXIT

L0387:  LD      DE,005Ch
        LD      C,16h
        CALL    BDOS
        CP      0FFh
        JP      NZ,L039F
        LD      DE,01C1h
        JP		WRITESTREXIT

L039F:  LD      HL,0500h
        LD      (L01E4),HL
L03A5:  LD      HL,(L01E4)
        EX      DE,HL
        LD      C,1Ah
        CALL    BDOS
        LD      DE,005Ch
        LD      C,15h
        CALL    BDOS
        OR      A
        JP      Z,L03CD
        LD      DE,01D7h
        CALL	WRITESTR
        LD      DE,005Ch
        LD      C,13h
        CALL    BDOS
        ;JP      0000h
		RST		0

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
        LD      DE,005Ch
        LD      C,10h
        CALL    BDOS
        RST		0
		;JP      0000h

        ; --- START PROC READER ---
READER:	JP		0F806h
		;CALL		0F806h
		;RET

		; --- START PROC PUNCHER ---
PUNCHER:
		;CALL		0F80Ch
		;RET
		JP		0F80Ch

WRITESTR:
		LD		C,C_WRITESTR
		JP		BDOS

READCHAR:
        LD      C,C_READ
        JP		BDOS

L03FC:  DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      0E6h
        DB      0E1h
        DB      0B1h
