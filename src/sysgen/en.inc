SIGNON:	DB	'SYSGEN VER '
	DB	(VERS / 10)+30h,'.',(VERS # 10)+30h
	DB	0
ASKGET:	DB	'SOURCE DRIVE NAME (OR RETURN TO SKIP)',0
GETMSG:	DB	'SOURCE ON '
GDISK:	DS	1	;FILLED IN AT GET FUNCTION
	DB	', THEN TYPE RETURN',0
ASKPUT:	DB	'DESTINATION DRIVE NAME (OR RETURN TO REBOOT)',0
PUTMSG:	DB	'DESTINATION ON '
PDISK:	DS	1	;FILLED IN AT PUT FUNCTION
	DB	', THEN TYPE RETURN',0
ERRMSG:	DB	'PERMANENT ERROR, TYPE RETURN TO IGNORE',0
DONE:	DB	'FUNCTION COMPLETE',0
QDISK:	DB	'INVALID DRIVE NAME (USE A, B, C, OR D)',0
NOFILE:	DB	'NO SOURCE FILE ON DISK',0
BADFILE:
	DB	'SOURCE FILE INCOMPLETE',0