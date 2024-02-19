@echo off

md log
md obj

SET PATH=tools;%PATH%

asw -qLU -i inc src\term\term.asm -olist log\term.lst -o obj\term.p
p2bin obj\term.p bin\term.bin

asw -qLU -i inc src\bios\bios.asm -olist log\bios.lst -o obj\bios.p
p2bin obj\bios.p bin\bios.bin

asw -qLU -i inc src\bdos\bdos.asm -olist log\bdos.lst -o obj\bdos.p
p2bin obj\bdos.p bin\bdos.bin

asw -qLU -i inc src\ccp\ccp.asm -olist log\ccp.lst -o obj\ccp.p
p2bin obj\ccp.p bin\ccp.bin

asw -qLU -i inc src\ch\ch.asm -olist log\ch.lst -o obj\ch.p
p2bin obj\ch.p com\ch.com

asw -qLU -i inc -i bin -i com src\loader\loader.asm -olist log\loader.lst -o obj\loader.p
p2bin obj\loader.p bin\loader.bin

:asw -qLU src\chdisk\chdisk.asm -olist log\chdisk.lst -o obj\chdisk.p
:p2bin obj\chdisk.p com\chdisk.com

asw -qLU src\dump\dump.asm -olist log\dump.lst -o obj\dump.p
p2bin obj\dump.p com\dump.com

asw -qLU src\romdisk\romdisk.asm -olist log\romdisk.lst -o obj\romdisk.p
p2bin obj\romdisk.p com\romdisk.com

cd src\stat\
asm80 MCD80A.ASM
SET :F1:=.
plm80 stat.plm pagewidth(100) debug optimize
link mcd80a.obj,stat.obj,plm80.lib to stat.mod
locate stat.mod code(0100H) stacksize(100) 
objcpm stat
cd ..\..

bin2rk bin\loader.bin rk\loader.rk 12544
bin2rk com\ch.com rk\ch.rk 256

:asw -1l comheader.asm > comheader.lst
