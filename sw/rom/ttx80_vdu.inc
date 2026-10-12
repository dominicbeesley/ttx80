.IFNDEF __TTX80_INC
.DEFINE __TTX80_INC

.IFNDEF __TTX80_ASM
		.import	my_WRCHV
		.import	my_OSBYTE

		.import crtcRegs80
		.import crtcRegsMode0
.ENDIF


MODE15_TEXT_COLS	= 80
MODE15_TEXT_ROWS	= 25
MODE15_ULA_CTL		= $5B
MODE0_ULA_CTL		= $9c

; Where WRCHV and BYTEV must point for *MODE15 to install, and where the hooks pass
; on to. This ROM can't store anything, so these are fixed at build time:
;
;   default      Integra-B with IBOS: the vectors point at small stubs in RAM
;                (JSR &0895 per vector) which must be passed through, not skipped
;   -D STOCK_MOS plain BBC B MOS 1.20: the MOS routines themselves
;
; *MODE15 refuses to install if the vectors are anything other than these.
.IFDEF STOCK_MOS
NEXT_WRCHV		= $E0A4
NEXT_BYTEV		= $E772
.ELSE
NEXT_WRCHV		= $0886
NEXT_BYTEV		= $0880
.ENDIF


.ENDIF