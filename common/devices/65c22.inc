.DEFINE V_CA1_CTRL_MASK BITS(%1, 0) EXPORT
.DEFINE V_CA1_POS_EDGE V_CA1_CTRL_MASK EXPORT
.DEFINE V_CA1_NEG_EDGE 0 EXPORT
.DEFINE V_CA2_CTRL_MASK BITS(%111, 1)
.DEFINE V_CA2_NEG_INDEPENDENT_IRQ BITS(%001, 1) EXPORT
.DEFINE V_CA2_POS_IRQ BITS(%010, 1) EXPORT
.DEFINE V_CA2_POS_INDEPENDENT_IRQ BITS(%011, 1) EXPORT
.DEFINE V_CA2_HANDSHAKE BITS(%100, 1) EXPORT
.DEFINE V_CA2_PULSE BITS(%101, 1) EXPORT
.DEFINE V_CA2_LOW BITS(%110, 1) EXPORT
.DEFINE V_CA2_HIGH V_CA2_CTRL_MASK EXPORT
.DEFINE V_CA2_NEG_IRQ 0 EXPORT
.DEFINE V_CB1_CTRL_MASK BITS(%1, 4) EXPORT
.DEFINE V_CB1_POS_EDGE V_CB1_CTRL_MASK EXPORT
.DEFINE V_CB1_NEG_EDGE 0 EXPORT
.DEFINE V_CB2_CTRL_MASK BITS(%111, 5)
.DEFINE V_CB2_NEG_INDEPENDENT_IRQ BITS(%001, 5) EXPORT
.DEFINE V_CB2_POS_IRQ BITS(%010, 5) EXPORT
.DEFINE V_CB2_POS_INDEPENDENT_IRQ BITS(%011, 5) EXPORT
.DEFINE V_CB2_HANDSHAKE BITS(%100, 5) EXPORT
.DEFINE V_CB2_PULSE BITS(%101, 5) EXPORT
.DEFINE V_CB2_LOW BITS(%110, 5) EXPORT
.DEFINE V_CB2_HIGH V_CB2_CTRL_MASK EXPORT
.DEFINE V_CB2_NEG_IRQ 0 EXPORT

;.DEFINE V_CA1_POS_IRQ_ENABLE CA1_CTRL_MASK EXPORT
;.DEFINE V_CB1_CTRL_MASK CA1_CTRL_MASK EXPORT
;.DEFINE V_CB1_NEG_IRQ_DISABLE CA1_NEG_IRQ_DISABLE EXPORT
;.DEFINE V_CB1_NEG_IRQ_ENABLE CA1_NEG_IRQ_ENABLE EXPORT
;.DEFINE V_CB1_POS_IRQ_DISABLE CA1_POS_IRQ_DISABLE EXPORT
;.DEFINE V_CB1_POS_IRQ_ENABLE CA1_POS_IRQ_ENABLE 
;.DEFINE V_CA2_CTRL_MASK BITS(%111, 3) EXPORT
;.DEFINE V_CA2_NEG_IRQ_DISABLE BITS(%000, 3) EXPORT
;.DEFINE V_CA2_NEG_IRQ_ENABLE BITS(%001, 3) EXPORT
;.DEFINE V_CA2_POS_IRQ_DISABLE BITS(%010, 3) EXPORT
;.DEFINE V_CA2_POS_IRQ_ENABLE BITS(%011, 3) EXPORT
;.DEFINE V_CA2_HANDSHAKE BITS(%100, 3) EXPORT
;.DEFINE V_CA2_PULSE BITS(%101, 3) EXPORT
;.DEFINE V_CA2_LOW BITS(%110, 3) EXPORT
;.DEFINE V_CA2_HIGH CA2_CTRL_MASK EXPORT
;.DEFINE V_CB2_CTRL_MASK CA2_CTRL_MASK EXPORT
;.DEFINE V_CB2_NEG_IRQ_DISABLE CA2_NEG_IRQ_DISABLE EXPORT
;.DEFINE V_CB2_NEG_IRQ_ENABLE CA2_NEG_IRQ_ENABLE EXPORT
;.DEFINE V_CB2_POS_IRQ_DISABLE CA2_POS_IRQ_DISABLE EXPORT
;.DEFINE V_CB2_POS_IRQ_ENABLE CA2_POS_IRQ_ENABLE EXPORT
;.DEFINE V_CB2_HANDSHAKE CA2_HANDSHAKE EXPORT
;.DEFINE V_CB2_PULSE CA2_PULSE EXPORT
;.DEFINE V_CB2_LOW CA2_LOW EXPORT
;.DEFINE V_CB2_HIGH CB2_CTRL_MASK EXPORT

.DEFINE IRQ_A_MASK BITS(%11, 6) EXPORT
.DEFINE IRQ_A1 BITS(%10, 6) EXPORT
.DEFINE IRQ_A2 BITS(%01, 6) EXPORT
.DEFINE IRQ_B_MASK IRQ_A_MASK EXPORT
.DEFINE IRQ_B1 IRQ_A1 EXPORT
.DEFINE IRQ_B2 IRQ_A2 EXPORT

.STRUCT VIA
IRB .DB
ORB DB
IRA .DB
ORA DB
DDRA DB
DDRB DB
T1CL DB
T1CH DB
T1LL DB
T1LH DB
T2CL DB
T2CH DB
SR DB
ACR DB
PCR DB
IFR DB
IER DB
IRA_NOHS .DB
ORA_NOHS DB
.ENDST