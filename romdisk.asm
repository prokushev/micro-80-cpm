; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80 CP/M 2.2 ROMDISK
; ═══════════════════════════════════════════════════════════════════════
; Драйвер ROM-диска. Перехватывает функции обращения к файлам для
; доступа к файлам на ROM-диске. Будем пока считать, что это диск B
; Имена файлов тут 5+3 (т.к. на ROM-диске всего 8 байт для имени файла)
; Пока это концепт, а не рабочий вариант.

	CPU	8080
	Z80SYNTAX	EXCLUSIVE

	ORG	100H
; serial number (not documented in original DRI source file)
	db	0	; OEM number, low byte
	db	0	; CP/M version, 16h = 2.2
	db	0	; OEM number, high byte
	db	0,0,0	; serial number, big-endian

;	enter here from the user's program with function number in c,
;	and information address in d,e
	jp	bdose	;past parameter block

;	************************************************
;	*** relative locations 0009 - 000e           ***
;	************************************************
pererr:	dw	persub	;permanent error subroutine
selerr:	dw	selsub	;select error subroutine
roderr:	dw	rodsub	;ro disk error subroutine
roferr:	dw	rofsub	;ro file error subroutine

bdose:
	; Тут должны перехватить обращение к файлам,
	; а для прочего звать оригинальный BDOS
	LD	C, A	; Номер функии
	CP	14	; Функции >= 14
	CP	26	; Функции <=26
	; может еще какие номера...
	ret

;	error subroutines
persub:	;report permanent error
;	Тут должны звать оригинальный BDOS
	ret

selsub:	;report select error
;	Тут должны звать оригинальный BDOS
	ret

rodsub:	;report write to read/only disk
;	Тут должны звать оригинальный BDOS
	ret
;
rofsub:	;report read/only file
;	Тут должны звать оригинальный BDOS
	ret
;

;DRV_SET:
;F_OPEN:
;F_CLOSE:
;F_SFIRST:
;F_SNEXT:
;F_DELETE: -ERROR
;F_READ:
;F_WRITE: -ERROR
;F_MAKE: -ERROR
;F_RENAME: -ERROR
;F_DMAOFF:
