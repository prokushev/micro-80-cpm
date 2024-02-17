; ═══════════════════════════════════════════════════════════════════════
;  МОНИТОРы для Радио-86РК для КР580, совместимые с Орион-128,
;  поддержкой VT-52 и эмулятором CP/M
; ───────────────────────────────────────────────────────────────────────
;  Системные вызовы МОНИТОРа
; ═══════════════════════════════════════════════════════════════════════

ColdBoot			EQU	0F800H
InputSymbol			EQU	0F803H
PrintCharFromC			EQU	0F809H
TapeWriteByte			EQU	0F80CH
GetKeyboardStatus		EQU	0F812H
PrintString			EQU	0F818H
PrintHexByte			EQU	0F815H
ReadKeyCode			EQU	0F81BH
GetCursorPos			EQU	0F81EH
ReadVideoRAM			EQU	0F821H
TapeReadBlock			EQU	0F824H
TapeWriteBlock			EQU	0F827H
CalcChecksum			EQU	0F82AH
InitVideo			EQU	0F82Dh
GetFreeMemAddr			EQU	0F830H
SetFreeMemAddr			EQU	0F833H
SetCursorPos			EQU	0F83CH
Beep				EQU	0F83FH

WarmBoot			EQU	0F86CH
InputDirective			EQU	0F8EEH
Compare_HL_DE			EQU	0F990H
PrintCR				EQU	0F9B0H
ReadROM				EQU	0FA68H
PrintCRAndHexWordAndSpace	EQU	0FB78H
AltBeep				EQU	0FD27H
