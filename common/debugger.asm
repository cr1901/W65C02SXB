; https://www.westerndesigncenter.com/wdc/documentation/WDCMON_User_Manual.pdf
; The WDCMON uses RAM memory from $00:7D00 - $00:7FFF for Registers, Flags, and Shadow
; Vectors. It also uses Zero Page RAM ($00:0000 - $00:0005).
.RAMSECTION "DEBUGGER_ZERO_PAGE"
. DSB 5 ; 
.ENDS

.DEFINE ZERO_PAGE_START $5 EXPORT

; The $00D0-00DF addresses are reserved for the hardware breakpoint registers.
.RAMSECTION "BREAKPOINT_ZERO_PAGE"
. DSB 16
.ENDS

.RAMSECTION "STACK_PAGE"
. DSB 256
.ENDS

.DEFINE MAIN_RAM_START $200 EXPORT

; Official code samples stop at $7c00, so let's do the same.
.RAMSECTION "DEBUGGER_MAIN_RAM"
. DSB 768 ; Peripherals at $7f00
.ENDS

.DEFINE VECTOR_ORG $7efa EXPORT
