.SUFFIXES: .asm .lib

APP=hello

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
LIBS=../common/periph.lib ../common/debugger.lib ../common/cookie.lib

$(APP).bin: $(APP).o $(LIBS) linkfile
	$(LD) $(LDFLAGS) linkfile $@

../common/periph.lib: $(DEVICES)

.asm.lib:
	$(AR) $(ARFLAGS) $@ $<

$(APP).o: $(HEADERS)

.asm.o:
	$(AS) -DUSING_DEBUGGER=1 $(ASFLAGS) $@ $<

prog: $(APP).bin
	$(PROG) $(PORT) load-exec $(APP).bin raw -m

clean:
	$(RM) $(RMFLAGS) *.o *.bin *.lst *.sym ../common/*.lib
