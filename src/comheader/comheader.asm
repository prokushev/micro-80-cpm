; ──────────────────────────────────────────────
; Блок защиты запуска файлов COM под MS-DOS
; Его подключаем к COM-файлу CP/M-80.
; ──────────────────────────────────────────────

	CPU	8080
	Z80SYNTAX EXCLUSIVE
	
	ORG	100H

;       8080		;       8086
	EX	DE,HL	; 	JMPS LABEL	; Переход на 8086 код
	LD	B, B	;
	
	EX	DE,HL	; 	DB 0EBH
	JP	TOPCOPY	; 	DB 0C3H ! DW TOPCOPY
	
	CPU	8086

BVMES:	DB	0dh,0ah,"This CP/M-80 program can't be executed under MS-DOS.   ",0dh,0ah,"$"
LABEL:	MOV	AH,9
	MOV	DX, BVMES
	INT	21H
	INT	20H

	CPU	8080
	Z80SYNTAX EXCLUSIVE

COMFILESTART:
	BINCLUDE	"BIN.BIN"
COMFILEEND:

; ──────────────────────────────────────────────
; Перемещаем программу и передаем ей управление
; ──────────────────────────────────────────────
	LD	HL, COMFILESTART
	LD	DE, 100H
	LD	BC, COMFILEEND-COMFILESTART
TOPCOPY:
	LD	A, (HL)
	LD	(DE), A
	INC	HL
	INC	DE
	DEC	BC
	LD	A, B
	OR	C
	JP	NZ, TOPCOPY
	
	JP	0100H
