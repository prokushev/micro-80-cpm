@echo off

md log
md obj

SET PATH=tools;%PATH%
SET PLM80 %CD%

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


SET :F1:=src\stat\
SET :F2:=obj
SET :F3:=lib
SET :F4:=com
SET :F5:=log
asm80 :F1:MCD80A.ASM object(:F2:mcd80a.obj) print(:F5:mcd80.lst)
plm80 :F1:stat.plm pagewidth(100) debug optimize object(:F2:stat.obj) print(:F5:stat.lst)
link :F2:mcd80a.obj,:F2:stat.obj,:F3:plm80.lib to :F2:stat.mod
locate :F2:stat.mod to :F4:stat code(0100H) stacksize(100)
objcpm :F4:stat
del com\stat
del com\stat.lin
del com\stat.sym

SET :F1:=src\pip\
plm80 :F1:pip.plm pagewidth(100) debug optimize object(:F2:pip.obj) print(:F5:pip.lst)
link :F2:mcd80a.obj,:F2:pip.obj,:F3:plm80.lib to :F2:pip.mod
locate :F2:pip.mod to :F4:pip code(0100H) stacksize(100)
objcpm :F4:pip
del com\pip
del com\pip.lin
del com\pip.sym

SET :F1:=src\load\
plm80 :F1:load.plm pagewidth(100) debug optimize object(:F2:load.obj) print(:F5:load.lst)
link :F2:mcd80a.obj,:F2:load.obj,:F3:plm80.lib to :F2:load.mod
locate :F2:load.mod to :F4:load code(0100H) stacksize(100)
objcpm :F4:load
del com\load
del com\load.lin
del com\load.sym

SET :F1:=src\ed\
plm80 :F1:ed.plm pagewidth(80) debug  object(:F2:ed.obj) print(:F5:ed.lst)
link :F2:mcd80a.obj,:F2:ed.obj,:F3:plm80.lib to :F2:ed.mod
locate :F2:ed.mod to :F4:ed code(0100H) stacksize(100)
objcpm :F4:ed
del com\ed
del com\ed.lin
del com\ed.sym

SET :F1:=src\submit\
plm80 :F1:submit.plm pagewidth(100) debug optimize object(:F2:submit.obj) print(:F5:submit.lst)
link :F2:mcd80a.obj,:F2:submit.obj,:F3:plm80.lib to :F2:submit.mod
locate :F2:submit.mod to :F4:submit code(0100H) stacksize(100)
objcpm :F4:submit
del com\submit
del com\submit.lin
del com\submit.sym

asw -qLU -i inc src\asm\AS0COM.asm -olist log\AS0COM.lst -o obj\AS0COM.p
p2bin obj\AS0COM.p bin\AS0COM.bin

asw -qLU -i inc src\asm\AS1IO.asm -olist log\AS1IO.lst -o obj\AS1IO.p
p2bin obj\AS1IO.p bin\AS1IO.bin

asw -qLU -i inc src\asm\AS2SCA.asm -olist log\AS2SCA.lst -o obj\AS2SCA.p
p2bin obj\AS2SCA.p bin\AS2SCA.bin

asw -qLU -i inc src\asm\AS3SYM.asm -olist log\AS3SYM.lst -o obj\AS3SYM.p
p2bin obj\AS3SYM.p bin\AS3SYM.bin

asw -qLU -i inc src\asm\AS4SEA.asm -olist log\AS4SEA.lst -o obj\AS4SEA.p
p2bin obj\AS4SEA.p bin\AS4SEA.bin

asw -qLU -i inc src\asm\AS5OPE.asm -olist log\AS5OPE.lst -o obj\AS5OPE.p
p2bin obj\AS5OPE.p bin\AS5OPE.bin

asw -qLU -i inc src\asm\AS6MAI.asm -olist log\AS6MAI.lst -o obj\AS6MAI.p
p2bin obj\AS6MAI.p bin\AS6MAI.bin

copy /b bin\AS0COM.bin + /b bin\AS1IO.bin + /b bin\AS2SCA.bin + /b bin\AS3SYM.bin + /b bin\AS4SEA.bin + /b bin\AS5OPE.bin + /b bin\AS6MAI.bin /b com\asm.com

asw -qLU -i inc src\sysgen\sysgen.asm -olist log\sysgen.lst -o obj\sysgen.p
p2bin obj\sysgen.p com\sysgen.com

asw -qLU -i inc src\ddt\DDT0MOV.asm -olist log\DDT0MOV.lst -o obj\DDT0MOV.p
p2bin obj\DDT0MOV.p bin\DDT0MOV.bin

asw -qLU -i inc src\ddt\DDT1ASM.asm -olist log\DDT1ASM.lst -o obj\DDT1ASM.p
p2bin obj\DDT1ASM.p bin\DDT1ASM.bin

asw -qLU -i inc src\ddt\DDT2MON.asm -olist log\DDT2MON.lst -o obj\DDT2MON.p
p2bin obj\DDT2MON.p bin\DDT2MON.bin

rem В формате МОНИТОРа
bin2rk bin\loader.bin rk\loader.rk8 12544
bin2rk com\ch.com rk\ch.rk8 256

rem В формате CH.COM
bin2ch com\stat.com rk\stat.rk
bin2ch com\pip.com rk\pip.rk
bin2ch com\load.com rk\load.rk
bin2ch com\ed.com rk\ed.rk
bin2ch com\submit.com rk\submit.rk
bin2ch com\ch.com rk\ch.rk
bin2ch com\dump.com rk\dump.rk
bin2ch com\asm.com rk\asm.rk
bin2ch com\sysgen.com rk\sysgen.rk
bin2ch com\power.com rk\power.rk
bin2ch com\power.com rk\pwretool.rk
bin2ch com\basic.com rk\basic.rk

:asw -1l comheader.asm > comheader.lst
