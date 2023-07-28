.SUFFIXES: .asm .lib

APP=echo

AS=wla-65c02
ASFLAGS=-I ../common -x -i -k -o
AR=wla-65c02
ARFLAGS=-I ../common -k -l
LD=wlalink
LDFLAGS=-i -S
PROG=cargo run --manifest-path=../sxbtools/Cargo.toml
RM=rm
RMFLAGS=-rf

HEADERS=../common/macros.inc ../common/header.inc
DEVICES=../common/devices/65c21.inc ../common/devices/65c22.inc \
	../common/devices/65c51.inc
LIBS=../common/periph.lib ../common/debugger.lib ../common/cookie.lib \
#	../common/serial.lib

$(APP).bin: $(APP).o serial.o $(LIBS) linkfile
	$(LD) $(LDFLAGS) linkfile $@

../common/periph.lib: $(DEVICES)
# ../common/serial.lib: $(DEVICES)

.asm.lib:
	$(AR) $(ARFLAGS) $@ $<

# I want listfile info, which doesn't work with libraries, so use an object
# for now.
serial.o: ../common/serial.asm $(HEADERS)
	$(AS) -DUSING_DEBUGGER=1 $(ASFLAGS) $@ $<

pstr.o: ../common/pstr.asm $(HEADERS)
	$(AS) -DUSING_DEBUGGER=1 $(ASFLAGS) $@ $<

$(APP).o: $(HEADERS)

.asm.o:
	$(AS) -DUSING_DEBUGGER=1 $(ASFLAGS) $@ $<

prog: $(APP).bin
	$(PROG) $(PORT) load-exec $(APP).bin raw -l 0x200

clean:
	$(RM) $(RMFLAGS) *.o *.bin *.lst *.sym ../common/*.lib
