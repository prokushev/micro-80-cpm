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

SET :F1:=src\asm\
asm80 :F1:AS0COM.ASM object(:F2:AS0COM.obj) print(:F5:AS0COM.lst)
asm80 :F1:AS1IO.ASM object(:F2:AS1IO.obj) print(:F5:AS1IO.lst)
asm80 :F1:AS2SCA.ASM object(:F2:AS2SCA.obj) print(:F5:AS2SCA.lst)
asm80 :F1:AS3SYM.ASM object(:F2:AS3SYM.obj) print(:F5:AS3SYM.lst)
asm80 :F1:AS4SEA.ASM object(:F2:AS4SEA.obj) print(:F5:AS4SEA.lst)
asm80 :F1:AS5OPE.ASM object(:F2:AS5OPE.obj) print(:F5:AS5OPE.lst)
asm80 :F1:AS6MAI.ASM object(:F2:AS6MAI.obj) print(:F5:AS6MAI.lst)

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

:asw -1l comheader.asm > comheader.lst
