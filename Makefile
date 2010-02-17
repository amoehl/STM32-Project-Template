################################################################################ 
# author  Andre Moehl
# version  v0.01
# date 02/2010
# based on Makefile from Piotr Esden-Tempski
############################################################################### 
#
# 	  This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>
#
###############################################################################

NAME		?= Projectname
PREFIX		?= arm-elf
OOCD_INTERFACE	?= jtagkey-tiny
OOCD_TARGET	?= olimex_stm32_f103

VERBOSE		?= 0

# Use 'make VERBOSE=1' for more debug output.
ifneq ($(VERBOSE),1)
Q := @
endif

CC		= $(PREFIX)-gcc
LD		= $(PREFIX)-ld
AR		= $(PREFIX)-ar
AS		= $(PREFIX)-as
CP		= $(PREFIX)-objcopy
OD		= $(PREFIX)-objdump
SIZE		= $(PREFIX)-size
OOCD		= openocd

#TOOLCHAIN_LIB_DIR = `dirname \`which $(CC)\``/../$(PREFIX)/lib
TOOLCHAIN_LIB_DIR = /opt/gnuarm/arm-elf/lib

CFLAGS		= -I. -Ipwm -Wall -ansi -std=c99 -c -fno-common -O0 -g \
		  -mcpu=cortex-m3 -mthumb -ffunction-sections -fdata-sections
ASFLAGS		= -ahls -mapcs-32
LDFLAGS		= -Tstm32.ld -nostartfiles -L$(TOOLCHAIN_LIB_DIR) -Os \
		  --gc-sections
LDLIBS		= -lcmsis -lstm32
CPFLAGS		= -j .isr_vector -j .text -j .data
ODFLAGS		= -S
SIZEFLAGS	= -A -x

OBJECTS = main.o \
			exceptions.o \
			vector_table.o 
	

all: gccversion images size

.SUFFIXES: .elf .bin .hex .srec .lst

images: $(NAME).bin $(NAME).hex $(NAME).srec $(NAME).lst

$(NAME).elf: $(OBJECTS)
	@echo "  LD    $@"
	$(Q)$(LD) $(LDFLAGS) -o $(NAME).elf $(OBJECTS) $(LDLIBS)

clean:
	@for i in $(OBJECTS) $(NAME).elf $(NAME).hex $(NAME).bin $(NAME).lst $(NAME).srec; do \
		echo "  CLEAN $$i"; \
		rm -f $$i; \
	done

flash: $(NAME).hex
	@echo "  OOCD  $<"
	$(Q)$(OOCD) -f interface/$(OOCD_INTERFACE).cfg \
		    -f board/$(OOCD_TARGET).cfg \
		    -c init \
		    -c "reset halt" \
		    -c "flash write_image erase $(NAME).hex" \
		    -c reset \
		    -c shutdown

gccversion:
	@$(CC) --version

size: $(NAME).elf
	@echo
	$(Q)$(SIZE) $(SIZEFLAGS) $<

# Suffix rules

.elf.bin:
	@echo "  CP    $@"
	$(Q)$(CP) $(CPFLAGS) -Obinary $< $@

.elf.hex:
	@echo "  CP    $@"
	$(Q)$(CP) $(CPFLAGS) -Oihex $< $@

.elf.srec:
	@echo "  CP    $@"
	$(Q)$(CP) $(CPFLAGS) -Osrec $< $@

.elf.lst:
	@echo "  OD    $@"
	$(Q)$(OD) $(ODFLAGS) $(NAME).elf > $(NAME).lst

%.o: %.c %.h
	@echo "  CC    $@"
	$(Q)$(CC) $(CFLAGS) -c $< -o $@
