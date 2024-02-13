; ──────────────────────────────────────────────
; Блок защиты запуска файлов COM под MS-DOS
; Его подключаем к COM-файлу CP/M-80.
; ──────────────────────────────────────────────

	CPU	8080
	Z80SYNTAX EXCLUSIVE
	
	ORG	100H

;       8080		;       8086
	EX DE,HL	; 	JMPS LABEL	; Переход на 8086 код
	LD B, B		;
	
	EX DE,HL	; 	DB 0EBH
	JP TOPCOPY	; 	DB 0C3H ! DW TOPCOPY
	
BVMES:	DB 0dh,0ah,"This CP/M-80 program can't be executed under MS-DOS.   ",0dh,0ah,"$"
	DB 0B4h,09h	; LABEL:MOV AH,9
	DB 0BAh		;	MOV DX,OFFSET BVMES
	DW BVMES	;
	DB 0CDh,021h	;	INT 21H		; Печать сообщения
	DB 0CDh,020h	;	INT 20H		; Завершение программы

COMFILESTART:
	BINCLUDE	"COMFILE.BIN"
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
