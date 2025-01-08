# ======================================================================
# Common Makefile for USBtiny applications
#
# Macros to be defined before including this file:
#
# USBTINY	- the location of this directory
# TARGET_ARCH	- gcc -mmcu= option with AVR device type
# OBJECTS	- the objects in addition to the USBtiny objects
# FLASH_CMD	- command to upload firmware.hex to flash
# FUSES_CMD	- command to program the fuse bytes
# STACK		- maximum stack size (optional)
# FLASH		- flash size (optional)
# SRAM		- SRAM size (optional)
# SCHEM		- Postscript version of the schematic to be generated
#
# Copyright 2006-2010 Dick Streefland
#
# This is free software, licensed under the terms of the GNU General
# Public License as published by the Free Software Foundation.
# ======================================================================

check	= $(shell $(CC) $1 -c -xc /dev/null -o/dev/null 2>/dev/null && echo $1)

CC	= avr-gcc
OPTIM	= -Os -ffunction-sections $(call check,-fno-split-wide-types)
CFLAGS	= -g -Wall -I. -I$(USBTINY) $(OPTIM)
LDFLAGS	= -g -Wl,--relax,--gc-sections
MODULES = crc.o int.o usb.o $(OBJECTS)
UTIL	= $(USBTINY)/../util

firmware.hex:

all:		firmware.hex $(SCHEM)

clean:
	rm -f main.elf *.o tags *.sch~ gschem.log

clobber:	clean
	rm -f firmware.hex $(SCHEM)

main.elf:	$(MODULES)
	$(LINK.o) -o $@ $(MODULES)

firmware.hex:	main.elf $(UTIL)/check.py
	@python3 $(UTIL)/check.py main.elf $(STACK) $(FLASH) $(SRAM)
	avr-objcopy -j .text -j .data -O ihex main.elf firmware.hex

check:		main.elf $(UTIL)/check.py
	@python3 $(UTIL)/check.py main.elf $(STACK) $(FLASH) $(SRAM)

disasm:		main.elf
	avr-objdump -S main.elf

flash:
	$(FLASH_CMD)

fuses:
	$(FUSES_CMD)

crc.o:		$(USBTINY)/crc.S $(USBTINY)/def.h usbtiny.h
	$(COMPILE.c) $(USBTINY)/crc.S
int.o:		$(USBTINY)/int.S $(USBTINY)/def.h usbtiny.h
	$(COMPILE.c) $(USBTINY)/int.S
usb.o:		$(USBTINY)/usb.c $(USBTINY)/def.h $(USBTINY)/usb.h usbtiny.h
	$(COMPILE.c) $(USBTINY)/usb.c

main.o:		$(USBTINY)/usb.h

%.ps:		%.sch $(UTIL)/sch2ps
	$(UTIL)/sch2ps $<
