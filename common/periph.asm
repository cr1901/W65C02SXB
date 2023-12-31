.FUNCTION BITS(val, offs) (val << offs)

.INCLUDE "devices/65c21.inc"
.INCLUDE "devices/65c22.inc"
.INCLUDE "devices/65c51.inc"

.DEFINE PERIPHERALS_START $7f00 EXPORT

.RAMSECTION "PERIPHERALS_PAGE"
. DSB 256
.ENDS

.ENUM $7f00 ASC EXPORT
BUS0 DSB 32
BUS1 DSB 32
BUS2 DSB 32
BUS3 DSB 32 ; Unused
ACIA0 INSTANCEOF ACIA SIZE 32
PIA0 INSTANCEOF PIA SIZE 32
VIA0 INSTANCEOF VIA SIZE 32
TIDE INSTANCEOF VIA SIZE 32
.ENDE
