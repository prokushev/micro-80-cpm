SET PATH=tools;%PATH%

asw -lU -i . src\term\cpm64-term.asm > cpm64-term.lst
p2bin src\term\cpm64-term.p bin\cpm64-term.bin

asw -lU -i . src\bios\cpm64-bios.asm > cpm64-bios.lst
p2bin src\bios\cpm64-bios.p bin\cpm64-bios.bin

asw -lU -i . src\bdos\cpm64-bdos.asm > cpm64-bdos.lst
p2bin src\bdos\cpm64-bdos.p bin\cpm64-bdos.bin

asw -lU -i . src\ccp\cpm64-ccp.asm > cpm64-ccp.lst
p2bin src\ccp\cpm64-ccp.p bin\cpm64-ccp.bin

asw -lU src\ch\ch-com.asm > ch-com.lst
p2bin src\ch\ch-com.p com\ch.com

asw -lU -i . -i bin -i com src\loader\cpm64-loader.asm > cpm64-loader.lst
p2bin src\loader\cpm64-loader.p bin\cpm64-loader.bin

asw -lU src\chdisk\chdisk.asm > chdisk.lst
p2bin src\chdisk\chdisk.p com\chdisk.com

asw -lU src\dump\dump.asm > dump.lst
p2bin src\dump\dump.p com\dump.com

asw -lU src\romdisk\romdisk.asm > romdisk.lst
p2bin src\romdisk\romdisk.p com\romdisk.com

bin2rk bin\cpm64-loader.bin 12544
bin2rk com\ch.com 256

:asw -l comheader.asm > comheader.lst
