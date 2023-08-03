; Pascal string, len < 255 first, then string.
.MACRO PSTR ISOLATELOCAL
\1: .db @end - (\1 + 1), \2
@end
.ENDM

.MACRO LD16
lda #<\1
sta.w \2
lda #>\1
sta.w (\2 + 1)
.ENDM

.MACRO STZ16
stz.w \1
stz.w (\1 + 1)
.ENDM

.MACRO BLE
bcc \1
beq \1
.ENDM

.MACRO BGT
beq +
bcs \1
+
.ENDM

; End-of-text section. Generated from "mcookie". Used as an "unlikely to
; be assembled string" to determine where to stop uploading a program to the
; W65C02SXB.
.MACRO EOTCOOKIE
.HEX "ba486455aa10b2fb68090d9412e62da2"
.ENDM
