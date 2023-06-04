; МИКРО-80 CP/M 2.2 ЗАГРУЗЧИК
; Является обратным портом ЮТ-88 CP/M 2.2 на МИКРО-80
; todo автоопределение объема квазидиска
; todo Образ квазидиска теперь содержит полный набор Directory
; todo CH.COM добавлен в образ квазидиска

		CPU			8080
		Z80SYNTAX	EXCLUSIVE

		INCLUDE		CFG.INC

		ORG			3100h


		; Перемещение CCP/BDOS/BIOS по итоговым адресам
		LD			HL,3400h
		LD			DE,CCP
L3106:	LD			A,(HL)
		LD			(DE),A
		INC			HL
		INC			DE
		LD			A,H
		CP			ENDC/0ffh ;4Ch
		JP			NZ,L3106
		LD			A,L
		CP			ENDC-0ffH*(ENDC/0ffh) ;?? странно считает
		JP			NZ,L3106

		; Сохранение копии CP/M на квазидиске
		LD			SP,1C00h
		LD			HL,4FFFh
		LD			A,0FEh
		OUT			(40h),A
L3120:	LD			D,(HL)
		DEC			HL
		LD			E,(HL)
		DEC			HL
		PUSH		DE
		LD			A,H
		CP			33h
		JP			NZ,L3120
		LD			A,0FFh
		OUT			(40h),A

		; Перемещение эмулятора терминала по итоговым адресам
		LD			HL,31E0h
		LD			DE,TERM
L3135:	LD			A,(HL)
		LD			(DE),A
		INC			HL
		INC			DE
		LD			A,H
		CP			33h
		JP			NZ,L3135
		JP			0DA00h

		ORG			31E0H
		BINCLUDE	CPM64-TERM.BIN

		; Образ квазидиска - системная часть
		ORG			3400H
		BINCLUDE	CPM64-CCP.BIN
		ORG			3400H+800H
		BINCLUDE	CPM64-BDOS.BIN
		ORG			3400H+1600H
		BINCLUDE	CPM64-BIOS.BIN

ENDC	EQU			$

		; Продолжение образа квазидиска - директория и данные

		DB			64*32 DUP (0E5H)

