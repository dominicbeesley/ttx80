; (c) Dossytronics 2023


		.include "mosrom.inc"
		.include "oslib.inc"
		.include "ttx80.inc"

		.include "ttx80_utils.inc"
		.include "ttx80_romheader.inc"
		.include "ttx80_vdu.inc"

		.include "hardware.inc"

		.export cmdMode15
		.export cmdTTX80TEST


		.CODE

;------------------------------------------------------------------------------
; Commands
;------------------------------------------------------------------------------

; *MODE15 - hook WRCHV and BYTEV. The hooks pass on to NEXT_WRCHV/NEXT_BYTEV
; (see ttx80_vdu.inc), which is what they must currently point at, otherwise
; something else has redirected them and we'd skip it by passing straight on.
; (on an Integra-B these are IBOS's stubs, so those are passed through)

cmdMode15:
		php
		sei

		lda	WRCHV
		cmp	#<NEXT_WRCHV
		bne	@bad
		lda	WRCHV+1
		cmp	#>NEXT_WRCHV
		bne	@bad

		lda	BYTEV
		cmp	#<NEXT_BYTEV
		bne	@bad
		lda	BYTEV+1
		cmp	#>NEXT_BYTEV
		bne	@bad


		lda	#<my_WRCHV
		sta	EXT_WRCHV
		lda	#>my_WRCHV
		sta	EXT_WRCHV+1
		lda	zp_mos_curROM
		sta	EXT_WRCHV+2

		lda	#<my_OSBYTE
		sta	EXT_BYTEV
		lda	#>my_OSBYTE
		sta	EXT_BYTEV+1
		lda	zp_mos_curROM
		sta	EXT_BYTEV+2


		lda	#<EXTVEC_ENTER_WRCHV
		sta	WRCHV
		lda	#>EXTVEC_ENTER_WRCHV
		sta	WRCHV+1

		lda	#<EXTVEC_ENTER_BYTEV
		sta	BYTEV
		lda	#>EXTVEC_ENTER_BYTEV
		sta	BYTEV+1

		plp
	

		rts		

		; not as expected - is that because we are already active?
@bad:		lda	WRCHV
		cmp	#<EXTVEC_ENTER_WRCHV
		bne	@other
		lda	WRCHV+1
		cmp	#>EXTVEC_ENTER_WRCHV
		bne	@other
		lda	EXT_WRCHV+2
		cmp	zp_mos_curROM
		bne	@other
		plp
		M_ERROR
		.byte	$FF,"MODE15 is already active",0

@other:		plp
		M_ERROR
		.byte	$FF,"OSWRCH or OSBYTE is not the vector this ROM expects",0

cmdTTX80TEST:
		; force mode 0 to ensure palette is ready for switching
		lda	#22
		jsr	OSWRCH
		lda	#0
		jsr	OSWRCH

		;fill mode 0 screen with characters
		lda	#$30
		sta	zp_trans_tmp+1
		ldy	#0
		sty	zp_tmp_ptr
		sty	zp_trans_tmp
@lp2:		lda	#$c0
		sta	zp_tmp_ptr+1
@lp:		lda	(zp_tmp_ptr),Y
		sta	(zp_trans_tmp),Y
		iny
		bne	@lp
		inc	zp_trans_tmp+1
		bit	zp_trans_tmp+1
		bmi	@sk1
		inc	zp_tmp_ptr+1
		lda	zp_tmp_ptr+1
		cmp	#$C3
		bne	@lp
		beq	@lp2
@sk1:

		sei
		; turn off interrupts
@mainloop:

		ldx	#13
@l1:		lda	crtcRegs80,X
		stx	sheila_CRTC_reg
		sta	sheila_CRTC_rw
		dex
		bpl	@l1

		lda	#MODE15_ULA_CTL
		sta	sheila_VIDULA_ctl

		; latches
		lda	#4
		sta	sheila_SYSVIA_orb
		lda	#5
		sta	sheila_SYSVIA_orb

		ldx	#8
		ldy	#0
		lda	#<testcard
		sta	zp_tmp_ptr
		lda	#>testcard
		sta	zp_tmp_ptr+1
		lda	#0
		sta	zp_trans_tmp
		lda	#$78
		sta	zp_trans_tmp+1
@lp3:		lda	(zp_tmp_ptr),Y
		sta	(zp_trans_tmp),Y
		iny
		bne	@lp3
		inc	zp_tmp_ptr+1
		inc	zp_trans_tmp+1
		dex
		bne	@lp3

		ldx	#0
		ldy	#0
		lda	#0
		clc
@wl:		adc	#1
		bne	@wl
		dey
		bne	@wl
		dex	
		bne	@wl

		ldx	#13
@l2:		lda	crtcRegsMode0,X
		stx	sheila_CRTC_reg
		sta	sheila_CRTC_rw
		dex
		bpl	@l2

		lda	#MODE0_ULA_CTL
		sta	sheila_VIDULA_ctl

		; latches
		lda	#$4
		sta	sheila_SYSVIA_orb
		lda	#$D
		sta	sheila_SYSVIA_orb

		ldx	#120
		ldy	#0
		lda	#0
		clc
@wl2:		adc	#1
		bne	@wl2
		dey
		bne	@wl2
		dex	
		bne	@wl2

		jmp	@mainloop


;------------------------------------------------------------------------------
; Strings and tables
;------------------------------------------------------------------------------

		.SEGMENT "RODATA"
testcard:	.incbin	"testcard.mo15"



