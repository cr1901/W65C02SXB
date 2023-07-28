.INCLUDE "header.inc"
.INCLUDE "macros.inc"

.RAMSECTION "SerialZP"
xmit_hd DB
xmit_tail DB
rx_hd DB
rx_tail DB
pstr_loc DW
.ENDS

.RAMSECTION "SerialVars"
xmit_buf DSB 16
rx_buf DSB 16
last_err DB
.ENDS

.DEFINE TX_OUT_OF_BOUNDS 0x01 EXPORT
.DEFINE TX_BUFFER_FULL 0x02 EXPORT

.BANK 0 SLOT 1 ; Assembles without this. Placed after main program, but all addrs
               ; are off... hmmm...
.SECTION "Serial"
; Call before other routines.
; Clobbers: A
serial_init:
    ; Set up VIA Timer 2- leaves other bits alone
    lda #%00100000
    sei ; Initialize global state.
    tsb.w VIA0.ACR ; Countdown PB6 Timer 2 w/ external pulses. The 1.8432 MHz
                   ; RXC pin from the ACIA provides the pulses. While exact
                   ; pulse amount isn't critical, this probably means that
                   ; system clk must be a minimum of 4 MHz to reliably count
                   ; enough pulses.
                   ; TODO: Support decimated clocks derived from RXC for slower
                   ; systems.
    sta.w VIA0.IFR ; Clear existing Timer 2 interrupt if any.
    sta.w VIA0.IER ; Disable timer 2 interrupt.

    ; Set up ACIA- clobbers ACIA state
    lda #(ONE_STOP_BIT | BITS_8 | INTERNAL_RX_CLK | BAUD_DIV_16)
    sta.w ACIA0.CTRL
    lda #(DISABLE_PARITY | DISABLE_TX_IRQ | DISABLE_RX_IRQ)
    sta.w ACIA0.CMD

    stz xmit_hd
    stz xmit_tail
    stz rx_hd
    stz rx_tail

    ; Debug fill value, use 0 normally.
    ; lda #$EA
    ldx #0
@nextbuf
    ; sta xmit_buf,X
    stz xmit_buf,X
    inx
    cpx #16
    bcs @nextbuf

    cli ; End of initialization.
    rts

; Input: A contains char to send.
; Output: Negative flag set if buffer was full.
;         N clear if char was xferred to buffer or ACIA.
; Clobbers: X
; Thread-safe if used only with IRQ.
putc:
    tax
    sei ; This can probably be finer granularity, but let's start safe.

    ; Check if buffer empty
    lda xmit_tail
    sec
    sbc xmit_hd ; If head and tail are equal, buffer is empty.
    bne @aciabusy

    ; Buffer is empty...
    lda #%00100000 ; But it's possible the ACIA/VIA are still busy counting down.
    bit.w VIA0.IER ; This happens when the last char before buf was emptied is sending.
    bne @aciabusy  ; If that's the case, put the char in the buffer as to not
                   ; overwrite the exposed TX register, since the TX buffer is
                   ; broken on 14 MHz parts. The next IRQ will remove it.

    txa
    jsr putcacia ; If VIA T2 int is disabled, then ACIA/VIA are not busy. 
                  ; Send char, setup TX timers.
    lda #%00100000
    tsb.w VIA0.IER ; And enable the int.

    jsr cln ; Char successfully xferred.
    cli ; End of modifying global state.
    rts
@aciabusy:
    txa
    jsr _putcbuf_nb ; If buffer is not full, put a character in.
    cli ; End of modifying global state.
    rts

; Input: A contains char to send.
; Clobbers: A
; Not thread-safe.
putcacia:
    ; sei
    sta.w ACIA0.TDR
    lda #168 ; Need to wait 160 ticks minimum at 115200 baud (16 clocks/char
             ; * 10 chars). Use a margin of 5% to account for xtal tolerances.
    sta.w VIA0.T2CL
    lda #0
    sta.w VIA0.T2CH ; Permit more interrupts to occur when P6 counts down
                    ; (also clears IFR bit 5).
    ; cli
    rts

; Input: A contains char to send.
; Output: Negative flag set if buffer was full.
;         N clear if char was xferred to buffer.
; Clobbers: X
; Not thread-safe.
_putcbuf_nb:
    tax
    ; sei

    ; Check if buffer is full.
    lda xmit_tail
    sec
    sbc xmit_hd ; T - H
    and #%00001111 ; modulo 16
    cmp #1 ; If room for 1 left, buffer is full
    beq @full

    ; If not full, but char in buffer.
    txa
    ldx xmit_hd ; Store the character.
    sta xmit_buf,X
    tax
    inc xmit_hd ; Bump the head pointer
    lda #%11110000 ; modulo 16.
    trb xmit_hd
    txa
    ; cli
    jsr cln ; Char successfully stored.
    rts

; Return "wouldblock"
@full
    txa
    ; cli
    jsr sen
    rts
.ENDS

.SECTION "SerialISR"
serial_isr:
    pha
    phx
    ; Check if buffer empty
    lda xmit_tail
    sec
    sbc xmit_hd ; If head and tail are equal, buffer is empty
    beq @buf_empty

    ; If not empty, it's time to send a new character, so do it. Also set up
    ; T2C low/high to schedule another interrupt.
    ldx xmit_tail
    lda xmit_buf,X ; Get a char from the buffer
    jsr putcacia ; Transmit a new character
    inc xmit_tail ; Bump tail
    lda #%11110000 ; modulo 16.
    trb xmit_tail

@end:
    plx
    pla
    rti

; If empty, clear IRQ line/prevent it from reasserting out of our control,
; and disable T2 int.
@buf_empty:
    lda.w VIA0.T2CL ; Clear pending interrupt, another one won't arrive
                    ; until T2CH is set.
    lda #%00100000
    sta.w VIA0.IER ; Disable timer 2 interrupt to indicate to user thread
                   ; that "we aren't doing anything".
    jmp @end
.ENDS

; Clear Negative Flag by modifying flags on stack.
; Should immediately be followed with an RTS.
cln:
    php
    phx
    pha
    tsx
    lda #%01111111
    and $103,X
@cleanup:
    sta $103,X
    pla
    plx
    plp
    rts

; Set Negative Flag by modifying flags on stack.
; Should immediately be followed with an RTS.
sen:
    php
    phx
    pha
    tsx
    lda #%10000000
    ora $103,X
    sta $103,X
    jmp cln@cleanup
