; ═══════════════════════════════════════════════════════════════════════
;  Конфигурация CP/M
; ═══════════════════════════════════════════════════════════════════════

VERS		EQU	22	; x.x

		ifndef	CPP_ADDR
CCP_ADDR	EQU	0C400H	; CP/M CCP
		endif
		ifndef	BDOS_ADDR
BDOS_ADDR	EQU	0CC00H	; CP/M BDOS
		endif
		ifndef	BIOS_ADDR
BIOS_ADDR	EQU	0DA00H	; CP/M BIOS
		endif
		ifndef	TERM_ADDR
TERM_ADDR	EQU	0F500H	; Эмулятор терминала
		endif
M80FIX		EQU	2 	; 1-фикс через f81b, 2-фикс через f812

BIOS_HELLO	EQU	0	; 1-Выводить приветствие при запуске, 0-не выводить

; Конфигурация дисков
DISKSN		EQU	1	; Количество дисков
DISK_0_TRK	EQU	512	; trk количество дорожек
DISK_0_FSC	EQU	1	; fsc номер первого сектора на дорожке (обычно 0 или 1)
DISK_0_LSC	EQU	8	; lsc номер последнего сектора на дорожке
DISK_0_SKF	EQU	1	; skf "коэффициент сдвига" для преобразования номера сектора
DISK_0_OFS	EQU	6	; ofs число пропускаемых дорожек (word) (резерв под систему)
