.INCLUDE "header.inc"
.INCLUDE "macros.inc"

.RAMSECTION "ZP"
t1_cnt DB
.ENDS

.RAMSECTION "Vars"
.ENDS

.BANK 0 SLOT 1
.SECTION "ENTRY"
entry:
    jsr.w serial_init
    stz t1_cnt ; Send chars for 1/20 of a second, then take a break for
               ; remaining 19/20.
    lda #%00111111
    and.w VIA0.ACR
    ora #%01000000 ; Continuous mode, no output on PB7.
    sta.w VIA0.ACR
    LD16 (40000-2), VIA0.T1CL ; 200 interrupts every second at 8 MHz clock.
    lda #%11000000
    sta.w VIA0.IER ; Enable ints

    ldy #1
@next:
    lda hello,Y
@tryagain:
    ldx #20
    sei
    cpx t1_cnt
    cli
    bcs @notbreaktime
    wai
    sta.w BUS0
    jmp @tryagain
@notbreaktime:
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
irq:
@tryvia0:
    bit.w VIA0.IFR
    bpl @tryacia0
    bvc @aciatx

    sta.w BUS2
    pha
    lda.w VIA0.T1CL ; Clear timer int
    lda #200 ; (pre)increment software cnt if below 200.
    inc t1_cnt
    cmp t1_cnt
    bcs @dontzero ;But we should zero as soon as we reach 200.
    stz t1_cnt
@dontzero:
    pla
    rti

@aciatx:
    jmp serial_isr

@tryacia0:
    bit.w ACIA0.STAT
    bmi @trypia0a
@aciarx:
    jmp serial_isr

@trypia0a:
    bit.w PIA0.CRA
    bmi @trypia0b

@trypia0b:
    bit.w PIA0.CRB
    bmi @phantom

@phantom: jmp @phantom

unused:
    jmp unused
.ENDS

; FIXME: WLA doesn't handle ROM/RAM collisions well...
; Bare .ORGA without a section also works, but at least this signifies intent.
; The user is _expected_ to overwrite these debugger vars.
.BANK 0 SLOT 1
.SECTION "Vectors" OVERWRITE ORGA VECTOR_ORG
.dw unused
.dw entry
.dw irq
.ENDS
