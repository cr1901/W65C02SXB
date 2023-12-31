.DEFINE P_CA1_CTRL_MASK BITS(%11, 0) EXPORT
.DEFINE P_CA1_NEG_IRQ_DISABLE BITS(%00, 0) EXPORT
.DEFINE P_CA1_NEG_IRQ_ENABLE BITS(%01, 0) EXPORT
.DEFINE P_CA1_POS_IRQ_DISABLE BITS(%10, 0) EXPORT
.DEFINE P_CA1_POS_IRQ_ENABLE P_CA1_CTRL_MASK EXPORT
.DEFINE P_CB1_CTRL_MASK P_CA1_CTRL_MASK EXPORT
.DEFINE P_CB1_NEG_IRQ_DISABLE P_CA1_NEG_IRQ_DISABLE EXPORT
.DEFINE P_CB1_NEG_IRQ_ENABLE P_CA1_NEG_IRQ_ENABLE EXPORT
.DEFINE P_CB1_POS_IRQ_DISABLE P_CA1_POS_IRQ_DISABLE EXPORT
.DEFINE P_CB1_POS_IRQ_ENABLE P_CA1_POS_IRQ_ENABLE 

.DEFINE P_DDRA_MASK BITS(%1, 2) EXPORT
.DEFINE P_ACCESS_PIA P_DDRA_MASK EXPORT
.DEFINE P_ACCESS_DDRA 0 EXPORT
.DEFINE P_DDRB_MASK P_DDRA_MASK EXPORT
.DEFINE P_ACCESS_PIB P_DDRB_MASK EXPORT
.DEFINE P_ACCESS_DDRB 0 EXPORT

.DEFINE P_CA2_CTRL_MASK BITS(%111, 3) EXPORT
.DEFINE P_CA2_NEG_IRQ_DISABLE BITS(%000, 3) EXPORT
.DEFINE P_CA2_NEG_IRQ_ENABLE BITS(%001, 3) EXPORT
.DEFINE P_CA2_POS_IRQ_DISABLE BITS(%010, 3) EXPORT
.DEFINE P_CA2_POS_IRQ_ENABLE BITS(%011, 3) EXPORT
.DEFINE P_CA2_HANDSHAKE BITS(%100, 3) EXPORT
.DEFINE P_CA2_PULSE BITS(%101, 3) EXPORT
.DEFINE P_CA2_LOW BITS(%110, 3) EXPORT
.DEFINE P_CA2_HIGH P_CA2_CTRL_MASK EXPORT
.DEFINE P_CB2_CTRL_MASK P_CA2_CTRL_MASK EXPORT
.DEFINE P_CB2_NEG_IRQ_DISABLE P_CA2_NEG_IRQ_DISABLE EXPORT
.DEFINE P_CB2_NEG_IRQ_ENABLE P_CA2_NEG_IRQ_ENABLE EXPORT
.DEFINE P_CB2_POS_IRQ_DISABLE P_CA2_POS_IRQ_DISABLE EXPORT
.DEFINE P_CB2_POS_IRQ_ENABLE P_CA2_POS_IRQ_ENABLE EXPORT
.DEFINE P_CB2_HANDSHAKE P_CA2_HANDSHAKE EXPORT
.DEFINE P_CB2_PULSE P_CA2_PULSE EXPORT
.DEFINE P_CB2_LOW P_CA2_LOW EXPORT
.DEFINE P_CB2_HIGH P_CB2_CTRL_MASK EXPORT

.DEFINE P_IRQ_A_MASK BITS(%11, 6) EXPORT
.DEFINE P_IRQ_A1 BITS(%10, 6) EXPORT
.DEFINE P_IRQ_A2 BITS(%01, 6) EXPORT
.DEFINE P_IRQ_B_MASK P_IRQ_A_MASK EXPORT
.DEFINE P_IRQ_B1 P_IRQ_A1 EXPORT
.DEFINE P_IRQ_B2 P_IRQ_A2 EXPORT

.STRUCT PIA
IRA .DB
ORA .DB
DDRA DB
CRA DB
IRB .DB
ORB .DB
DDRB DB
CRB DB
.ENDST
