.IFNDEF __TTX80_INC
.DEFINE __TTX80_INC

.IFNDEF __TTX80_ASM
		.import	my_WRCHV
		.import	my_OSBYTE

		.import crtcRegs80
		.import crtcRegsMode0
.ENDIF


MODE15_TEXT_COLS	= 80
MODE15_TEXT_ROWS	= 24
MODE15_ULA_CTL		= $5B
MODE0_ULA_CTL		= $9c
MOS_WRCHV_ORG		= $E0A4			; for now hard-code vdu vector pass on
MOS_BYTEV_ORG		= $E772

.ENDIF