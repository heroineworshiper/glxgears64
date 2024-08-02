CC65_DIR := /root/cc65-master/bin/
AS := $(CC65_DIR)ca65
CC := $(CC65_DIR)cc65
LD := $(CC65_DIR)ld65



disk.d64: glxgears glxgears2 cube2 cube
	c1541 -format "disk,00" d64 disk.d64
	c1541 -attach disk.d64 -write glxgears glxgears,p
	c1541 -attach disk.d64 -write glxgears2 glxgears2,p
	c1541 -attach disk.d64 -write cube2 cube2,p
	c1541 -attach disk.d64 -write cube cube,p
        

glxgears: glxgears.s gears.inc tables.inc common_code.inc common_vars.inc
	$(AS) -t c64 glxgears.s -DDOUBLE_SIDED
	$(LD) -m glxgears.map -t c64 glxgears.o -o glxgears c64.lib

glxgears2: glxgears2.s gears.inc tables.inc common_code.inc common_vars.inc
	$(AS) -t c64 glxgears2.s 
	$(LD) -m glxgears2.map -t c64 glxgears2.o -o glxgears2 c64.lib

#	c1541 -format "disk,00" d64 disk.d64
#	c1541 -attach disk.d64 -write glxgears glxgears,p

cube2: cube2.s tables.inc common_code.inc common_vars.inc
	$(AS) -t c64 cube2.s
	$(LD) -m cube2.map -t c64 cube2.o -o cube2 c64.lib
#	c1541 -format "disk,00" d64 disk.d64
#	c1541 -attach disk.d64 -write cube2 cube2,p

cube: cube.s
	$(AS) -t c64 cube.s
	$(LD) -t c64 cube.o -o cube c64.lib
#	c1541 -format "disk,00" d64 disk.d64
#	c1541 -attach disk.d64 -write cube cube,p

getc: getc.s
	$(AS) -v -t c64 getc.s
	$(LD) -t c64 getc.o -o getc c64.lib
	c1541 -format "disk,00" d64 disk.d64
	c1541 -attach disk.d64 -write getc getc,p

test: test.c
	$(CC) -Ors -T -t c64 test.c
	$(AS) -t c64 test.s
	$(LD) -t c64 test.o -o test c64.lib
	c1541 -format "disk,00" d64 disk.d64
	c1541 -attach disk.d64 -write test test,p

hello: hello.s
	$(AS) -t c64 hello.s
	$(LD) -t c64 hello.o -o hello c64.lib

#disk: hello
#	c1541 -format "disk,00" d64 disk.d64
#	c1541 -attach disk.d64 -write hello hello,p

#run: disk.d64
#	x64 -VICIIdsize -ntsc -warp -autostart disk.d64  

clean:
	rm -f *.map *.o *.lst cube cube2 glxgears test disk.d64

