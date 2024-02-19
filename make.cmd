@echo off

SET PATH=tools;%PATH%

asw -LU -i . src\term\term.asm -olist log\term.lst -o obj\term.p
p2bin obj\term.p bin\term.bin

asw -LU -i . src\bios\bios.asm -olist log\bios.lst -o obj\bios.p
p2bin obj\bios.p bin\bios.bin

asw -LU -i . src\bdos\bdos.asm -olist log\bdos.lst -o obj\bdos.p
p2bin obj\bdos.p bin\bdos.bin

asw -LU -i . src\ccp\ccp.asm -olist log\ccp.lst -o obj\ccp.p
p2bin obj\ccp.p bin\ccp.bin

asw -LU -i . src\ch\ch.asm -olist log\ch.lst -o obj\ch.p
p2bin obj\ch.p com\ch.com

asw -LU -i . -i bin -i com src\loader\loader.asm -olist log\loader.lst -o obj\loader.p
p2bin obj\loader.p bin\loader.bin

asw -LU src\chdisk\chdisk.asm -olist log\chdisk.lst -o obj\chdisk.p
p2bin obj\chdisk.p com\chdisk.com

asw -LU src\dump\dump.asm -olist log\dump.lst -o obj\dump.p
p2bin obj\dump.p com\dump.com

asw -LU src\romdisk\romdisk.asm -olist log\romdisk.lst -o obj\romdisk.p
p2bin obj\romdisk.p com\romdisk.com

bin2rk bin\loader.bin 12544
bin2rk com\ch.com 256

:asw -l comheader.asm > comheader.lst
