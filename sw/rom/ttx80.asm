; (c) Dossytronics 2023


		.include "mosrom.inc"
		.include "oslib.inc"
		.include "ttx80.inc"

		.include "ttx80_utils.inc"
		.include "ttx80_romheader.inc"
		.include "ttx80_vdu.inc"

		.export cmdMode15


		.CODE

;------------------------------------------------------------------------------
; Commands
;------------------------------------------------------------------------------

brkBadOrgVec:
		plp
		M_ERROR	
		.byte	$FF,"The WRCHV vector has already been redirected",0

cmdMode15:
		php
		sei
		lda	WRCHV
		cmp	#<MOS_WRCHV_ORG
		bne	brkBadOrgVec
		lda	WRCHV+1
		cmp	#>MOS_WRCHV_ORG
		bne	brkBadOrgVec

		lda	#<my_WRCHV
		sta	EXT_WRCHV
		lda	#>my_WRCHV
		sta	EXT_WRCHV+1
		lda	zp_mos_curROM
		sta	EXT_WRCHV+2

		lda	#<EXTVEC_ENTER_WRCHV
		sta	WRCHV
		lda	#>EXTVEC_ENTER_WRCHV
		sta	WRCHV+1

		plp
	

		rts		

;------------------------------------------------------------------------------
; Strings and tables
;------------------------------------------------------------------------------

		.SEGMENT "RODATA"




