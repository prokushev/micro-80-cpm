; ═══════════════════════════════════════════════════════════════════════
; Редиректор терминала для МИКРО-80/ЮТ-88 CP/M 2.2
; ═══════════════════════════════════════════════════════════════════════

	CPU		8080
	Z80SYNTAX	EXCLUSIVE

	INCLUDE	CFG.INC
	INCLUDE	syscalls.inc

	ORG	TERM_ADDR

	JP	PrintCharFromC		; 0 Печать символа на экран
	JP	InputSymbol		; 3 Ввод символа с клавиатуры
	JP	GetKeyboardStatus	; 6 Состояние клавиатуры
	JP	PrintString		; 9 Печать ASCIIZ строки

