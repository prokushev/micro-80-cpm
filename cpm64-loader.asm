; ═══════════════════════════════════════════════════════════════════════
; МИКРО-80 CP/M 2.2 ЗАГРУЗЧИК
; ═══════════════════════════════════════════════════════════════════════
; Является обратным портом ЮТ-88 CP/M 2.2 на МИКРО-80
; todo автоопределение объема квазидиска
; todo Образ квазидиска теперь содержит полный набор Directory
; todo CH.COM добавлен в образ квазидиска

	CPU		8080
	Z80SYNTAX	EXCLUSIVE
	
	INCLUDE		CFG.INC

	ORG		3100h


	; Перемещение CCP/BDOS/BIOS по итоговым адресам
	LD		HL,DISKIMAGE
	LD		DE,CCP
COPYLOOP:
	LD		A,(HL)
	LD		(DE),A
	INC		HL
	INC		DE
	LD		A,H
	CP		ENDC/0FFH
	JP		NZ,COPYLOOP
	LD		A,L
	CP		ENDC-0FFH*(ENDC/0FFh) ;?? странно считает
	JP		NZ,COPYLOOP

	; Сохранение копии CP/M на квазидиске
	LD		SP,1C00h
	LD		HL,4FFFh

	LD		A,0FEh
	OUT		(40h),A			; Подключаем первые 64кб RAMDISKа

L3120:	LD		D,(HL)
	DEC		HL
	LD		E,(HL)
	DEC		HL
	PUSH		DE
	LD		A,H
	CP		DISKIMAGE/0FFh-1	;33h
	JP		NZ,L3120

	LD		A,0FFh
	OUT		(40h),A			; Отключаем RAMDISK

	; Перемещение эмулятора терминала по итоговым адресам
	LD		HL,TERMIMAGE
	LD		DE,TERM
L3135:	LD		A,(HL)
	LD		(DE),A
	INC		HL
	INC		DE
	LD		A,H
	CP		DISKIMAGE/0FFh-1	;33h
	JP		NZ,L3135
	JP		BIOS

	ORG		31E0H
TERMIMAGE:
	BINCLUDE	CPM64-TERM.BIN

	; Образ квазидиска - системная часть
	ORG		3400H
DISKIMAGE:
	BINCLUDE	CPM64-CCP.BIN
	ORG		3400H+800H
	BINCLUDE	CPM64-BDOS.BIN
	ORG		3400H+1600H
	BINCLUDE	CPM64-BIOS.BIN
ENDC	EQU		$

	; Продолжение образа квазидиска - директория и данные
	DB		64*32 DUP (0E5H)

