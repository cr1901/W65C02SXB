.INCLUDE "header.inc"
.INCLUDE "macros.inc"

.RAMSECTION "HelloZP"
piaval DB
do_send DB
hello_str DW
.ENDS

.RAMSECTION "HelloVars"
.ENDS

.BANK 0 SLOT 1
.SECTION "ENTRY"
entry:
    ; Set up VIA Timer 1/2
    lda #%01100000 ; Timer 1 free-running, no PB7 output, Countdown PB6 Timer 2
    sta.w VIA0.ACR
    lda #$ff
    sta.w VIA0.T1CL ; Interrupt ~122 times/sec.
    sta.w VIA0.T1CH

    ; Set up ACIA
    lda #(ONE_STOP_BIT | BITS_8 | INTERNAL_RX_CLK | BAUD_DIV_16)
    sta.w ACIA0.CTRL
    lda #(DISABLE_PARITY | DISABLE_TX_IRQ | DISABLE_RX_IRQ)
    sta.w ACIA0.CMD

    ; Set up PIA Port A
    lda #P_ACCESS_DDRA
    sta.w PIA0.CRA
    lda #$ff
    sta.w PIA0.DDRA
    lda #(P_ACCESS_PIA | P_CA1_POS_IRQ_DISABLE | P_CA2_HANDSHAKE)
    sta.w PIA0.CRA

    ; Set up vars
    stz piaval
    lda #<hello
    sta hello_str
    lda #>hello
    sta hello_str + 1
    ldy #1
again:
    lda piaval
    inc piaval
    sta.w PIA0.ORA
    lda #$01
    sta do_send
    lda (hello_str), Y
    jsr kickstart_serial
    ldx #61 ; Wait half of 122 times/sec.
@outer:
@inner:
    lda.w VIA0.IFR
    bit #%01000000 ; Check for T1 int
    bne @break
    lda do_send ; Did we send everything?
    cmp #0
    beq @inner ; If yes, keep waiting
    lda.w VIA0.IFR
    bit #%00100000 ; If not done Check for T2 int
    beq @inner

    lda (hello_str), Y
    sta.w ACIA0.TDR
    lda.w VIA0.T2CL ; Clear pending interrupt, another one won't arrive
                    ; until T2CH is set.

    ; Compare to end of string idx, restart Y if there.
    tya
    cmp (hello_str)
    bcc @setup_next_char
    ldy #1
    stz do_send
    bra @inner

@setup_next_char:
    jsr setup_next_char
    bra @inner 
@break:
    lda.w VIA0.T1CL ; Clear timer int
    dex
    bne @outer
    jmp again

kickstart_serial:
    sta.w ACIA0.TDR
setup_next_char:
    iny
    lda #168 ; Need to wait 160 ticks minimum at 115200 baud (16 clocks/char
             ; * 10 chars). Use a margin of 5% to account for xtal tolerances.
    sta.w VIA0.T2CL
    lda #0
    sta.w VIA0.T2CH ; Permit more interrupts to occur when P6 counts down.
    rts

PSTR hello, "Hello World!!\n"

.ENDS

.SECTION "VectorsImpl"
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
.dw unused
.ENDS

