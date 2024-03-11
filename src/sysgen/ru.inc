SIGNON:	DB	'SYSGEN wer '
	DB	(VERS / 10)+30h,'.',(VERS # 10)+30h
	DB	0
ASKGET:	DB	'imq ishodnogo diska (ili wk dlq propuska)',0
GETMSG:	DB	'isto^nik na '
GDISK:	DS	1	;FILLED IN AT GET FUNCTION
	DB	', posle ^ego navmite wk',0
ASKPUT:	DB	'imq celevogo diska (ili wk dlq perezagruzki)',0
PUTMSG:	DB	'DESTINATION ON '
PDISK:	DS	1	;FILLED IN AT PUT FUNCTION
	DB	', THEN TYPE RETURN',0
ERRMSG:	DB	'PERMANENT ERROR, TYPE RETURN TO IGNORE',0
DONE:	DB	'FUNCTION COMPLETE',0
QDISK:	DB	'INVALID DRIVE NAME (USE A, B, C, OR D)',0
NOFILE:	DB	'net ishodnogo fajla na diske',0
BADFILE:
	DB	'ishodnxq fajl nepolnxj',0
