.INCLUDE "header.inc"
.INCLUDE "macros.inc"

.RAMSECTION "ZP"
.ENDS

.RAMSECTION "Vars"
.ENDS

.BANK 0 SLOT 1
.SECTION "ENTRY"
entry:
    jsr.w serial_init
    ldy #1
@next:
    lda hello,Y
@tryagain:
    jsr.w putc
    bmi @tryagain ; If busy, try to resend.
    ; bmi @busy
@incr:
    iny
    cpy.w hello
    beq @next
    bcs @reset_y
    jmp @next
@reset_y:
    ldy #1
    jmp @next

; @busy: jmp @busy
.ENDS

PSTR hello, "Hello World!!\nThis is a test of the buffer function!!\n"

.SECTION "VectorsImpl"
unused:
.ENDS

; FIXME: WLA doesn't handle ROM/RAM collisions well...
; Bare .ORGA without a section also works, but at least this signifies intent.
; The user is _expected_ to overwrite these debugger vars.
.BANK 0 SLOT 1
.SECTION "Vectors" OVERWRITE ORGA VECTOR_ORG
.dw unused
.dw entry
.dw serial_isr
.ENDS
