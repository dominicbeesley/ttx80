
		.include "hardware.inc"
		.include "mosrom.inc"

		.export	my_WRCHV
		.export	MOS_WRCHV_ORG
		.export  crtcRegs80
		.export  crtcRegsMode0

MOS_WRCHV_ORG	= $E0A4			; for now hard-code vdu vector pass on


		.CODE

my_WRCHV:	pha					; Save all registers
		txa					
		pha					
		tya					
		pha					
		bit	sysvar_ECO_OSBW_INTERCEPT		; Check OSWRCH interception flag
		bpl	__no_intercept			; Not set, skip interception call
call_org_vec:
		pla
		tay
		pla
		tax
		pla
		jmp	MOS_WRCHV_ORG


__no_intercept:	lda	sysvar_VDU_Q_LEN
		bne	call_org_vec

		lda	#'!'
		jsr	MOS_WRCHV_ORG

		pla
		tay
		pla
		tax
		pla
		jmp	MOS_WRCHV_ORG




		.RODATA


crtcRegs80:	.byte $7F,$50,$62,$28,$1E,$02,$19,$1B,$93,$12,$72,$13,$30,$00

crtcRegsMode0:	.byte $7F,$50,$62,$28,$26,$00,$20,$22,$01,$07,$67,$08,$06,$00