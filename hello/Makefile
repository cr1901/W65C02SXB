.SUFFIXES: .asm .lib

AS=wla-65c02
ASFLAGS=-I ../common -x -i -k -o
AR=wla-65c02
ARFLAGS=-I ../common -k -l
LD=wlalink
LDFLAGS=-i -S

HEADERS=../common/macros.inc ../common/header.inc
DEVICES=../common/devices/65c21.inc ../common/devices/65c22.inc \
	../common/devices/65c51.inc
LIBS=../common/periph.lib ../common/debugger.lib ../common/cookie.lib

hello.bin: hello.o $(LIBS) linkfile
	$(LD) $(LDFLAGS) linkfile $@

../common/periph.lib: $(DEVICES)

.asm.lib:
	$(AR) $(ARFLAGS) $@ $<

hello.o: $(HEADERS)

.asm.o:
	wla-65c02 -DUSING_DEBUGGER=1 $(ASFLAGS) $@ $<

prog: hello.bin
	cargo run --manifest-path=../sxbtools/Cargo.toml $(PORT) load-exec hello.bin raw -m

clean:
	rm -rf *.o *.bin *.lst *.sym ../common/*.lib
