; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80 CP/M 2.2 ROMDISK
; ═══════════════════════════════════════════════════════════════════════
; Драйвер ROM-диска. Перехватывает функции обращения к файлам для
; доступа к файлам на ROM-диске. Будем пока считать, что это диск B
; Имена файлов тут 5+3 (т.к. на ROM-диске всего 8 байт для имени файла)
; Пока это концепт, а не рабочий вариант.

	CPU	8080
	Z80SYNTAX	EXCLUSIVE

	org	100h

Start:
	JP	InitDriver

; todo: Новый BDOS. Его надо выравнять по границе 256 и сделать
; для него битовую маску для перемещения.

bdosstart:
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
pererr:	dw	0	;permanent error subroutine
selerr:	dw	0	;select error subroutine
roderr:	dw	0	;ro disk error subroutine
roferr:	dw	0	;ro file error subroutine

bdose:
	; Тут должны перехватить обращение к файлам,
	; а для прочего звать оригинальный BDOS
	LD	A, C	; Номер функии
	CP	14	; Функции >= 14
	CP	26	; Функции <=26
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
	; может еще какие номера...
	; Если мы не перехватываем функцию bdos, то уходим в старый BDOS
	DB	0C3h	; JP ...
OldBDOS:
	DW	0	; Точка входа в оригинальный BDOS
bdosend:

; Код ниже уходит в мусорку после инициализации драйвера

InitDriver:
	; Определяем начало BDOS
	LD	HL, (6)			; Точка входа в BDOS
	LD	(OldBDOS), HL		; Сохраняем ее
	LD	L, 0			; Начало BDOS
	LD	BC, -(bdosend-bdosstart); Размер драйвера
	ADD	HL, BC			; Новое начало нашего драйвера
	PUSH	HL
	PUSH	HL
	POP	BC
	LD	HL, bdosstart		; Текущее местоположение драйвера
	LD	DE, bdosend-bdosstart	; Размер драйвера
	ADD	HL, DE
	EX	DE, HL
	
	; todo: Перемещаем HL - начало, DE - конец, BC - новый адрес

	; todo: Накладываем битовую маску

	; todo: копируем серийный номер

	; todo: копируем вектора обработчиков ошибок

	; Перехватываем CALL 5
	POP	HL			; Новое начало BDOS
	LD	L, 6			; Смещение точки входа в новый bdos
	LD	(6), HL			; Патчим CALL 5

	; todo Перехватываем rst 0 для того, чтобы снова грузить наш драйвер при теплом старте.
	; todo грузим CPP.PRL
	
	; todo запускаем CCP

	; Все, теперь драйвер установлен и работает.
