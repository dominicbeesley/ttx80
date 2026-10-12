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
		.export initWksp

		.export callOldBYTEV
		.export callOldWRCHV


		.CODE

;------------------------------------------------------------------------------
; Commands
;------------------------------------------------------------------------------

cmdMode15:
		php
		sei

		jsr	SkipSpacesPTR
		cmp	#$D
		beq	@s2
		cmp	#'1'
		bne	@s
@s2:		jmp	cmdMode15_ON
@s:
		cmp	#'0'
		beq	cmdMode15_OFF

		cmp	#'P'
		beq	@cp
		jmp	brkBadCommand
@cp:		jmp	cmdMode15_PAGE

cmdMode15_OFF:	;;;;;;;;;;;;;;;;;;; TODO !!!!!!!!!!!!!!!!!!!!!
		; check flag in private workspace to see if we've actually
		; claimed

		jsr	getWksp
		bcs	@notcur
		ldy	#PW_CLAIMED
		lda	(zp_mos_genPTR),Y
		beq	@notcur

		; check we're actually the current head claimant - if not
		; there's not much we can do.
		lda	WRCHV
		cmp	#<EXTVEC_ENTER_WRCHV
		bne	@notcur
		lda	WRCHV+1
		cmp	#>EXTVEC_ENTER_WRCHV
		bne	@notcur
		lda	BYTEV
		cmp	#<EXTVEC_ENTER_BYTEV
		bne	@notcur
		lda	BYTEV+1
		cmp	#>EXTVEC_ENTER_BYTEV
		bne	@notcur

		lda	EXT_WRCHV
		cmp	#<my_WRCHV
		bne	@notcur
		lda	EXT_WRCHV+1
		cmp	#>my_WRCHV
		bne	@notcur
		lda	EXT_BYTEV
		cmp	#<my_OSBYTE
		bne	@notcur
		lda	EXT_BYTEV+1
		cmp	#>my_OSBYTE
		bne	@notcur
				

		jsr	setOldWRCHV
		jsr	setOldBYTEV

		plp
		rts

@notcur:		M_ERROR	
		.byte	$FF, "MODE15 active but we're not the most recent claimant, can't let go",0

brkNoWorkspace:	M_ERROR
		.byte	$FF, "No workspace, either *MODE15 PAGE or run from SWRAM",0


cmdMode15_ON:	jsr	getWksp
		bcs	brkNoWorkspace
		
		ldy	#PW_CLAIMED
		lda	(zp_mos_genPTR),Y
		bne	@already

		lda	#$80
		sta	(zp_mos_genPTR),Y		; mark as claimed

		; save old claimants, including extended to PW
		ldy	#PW_OLDC_WRCHV
		jsr	saveYWRCHV

		ldy	#PW_OLDC_BYTEV
		jsr	saveYBYTEV

		jsr	setMyWRCHV
		jsr	setMyBYTEV

		jsr	PrintImmed
		.byte	"DONE!",13,10,0

@already:	plp
		rts

saveYWRCHV:	lda	WRCHV+0
		sta	(zp_mos_genPTR),Y
		iny
		lda	WRCHV+1
		sta	(zp_mos_genPTR),Y
		iny

		lda	EXT_WRCHV+0
		sta	(zp_mos_genPTR),Y
		iny
		lda	EXT_WRCHV+1
		sta	(zp_mos_genPTR),Y
		iny
		lda	EXT_WRCHV+2
		sta	(zp_mos_genPTR),Y
		rts

saveYBYTEV:
		lda	BYTEV+0
		sta	(zp_mos_genPTR),Y
		iny
		lda	BYTEV+1
		sta	(zp_mos_genPTR),Y
		iny

		lda	EXT_BYTEV+0
		sta	(zp_mos_genPTR),Y
		iny
		lda	EXT_BYTEV+1
		sta	(zp_mos_genPTR),Y
		iny
		lda	EXT_BYTEV+2
		sta	(zp_mos_genPTR),Y
		rts



setMyWRCHV:	
		lda	#<EXTVEC_ENTER_WRCHV
		sta	WRCHV
		lda	#>EXTVEC_ENTER_WRCHV
		sta	WRCHV+1

		lda	#<my_WRCHV
		sta	EXT_WRCHV
		lda	#>my_WRCHV
		sta	EXT_WRCHV+1
		lda	zp_mos_curROM
		sta	EXT_WRCHV+2
		rts

setMyBYTEV:
		lda	#<EXTVEC_ENTER_BYTEV
		sta	BYTEV
		lda	#>EXTVEC_ENTER_BYTEV
		sta	BYTEV+1

		lda	#<my_OSBYTE
		sta	EXT_BYTEV
		lda	#>my_OSBYTE
		sta	EXT_BYTEV+1
		lda	zp_mos_curROM
		sta	EXT_BYTEV+2
		rts


setOldWRCHV:
		ldy	#PW_OLDC_WRCHV

setYWRCHV:
		lda	(zp_mos_genPTR),Y
		sta	WRCHV+0
		iny
		lda	(zp_mos_genPTR),Y
		sta	WRCHV+1
		iny

		lda	(zp_mos_genPTR),Y
		sta	EXT_WRCHV+0
		iny
		lda	(zp_mos_genPTR),Y
		sta	EXT_WRCHV+1
		iny
		lda	(zp_mos_genPTR),Y
		sta	EXT_WRCHV+2
		iny
		rts

setOldBYTEV:	ldy	#PW_OLDC_BYTEV

setYBYTEV:
		lda	(zp_mos_genPTR),Y
		sta	BYTEV+0
		iny
		lda	(zp_mos_genPTR),Y
		sta	BYTEV+1
		iny

		lda	(zp_mos_genPTR),Y
		sta	EXT_BYTEV+0
		iny
		lda	(zp_mos_genPTR),Y
		sta	EXT_BYTEV+1
		iny
		lda	(zp_mos_genPTR),Y
		sta	EXT_BYTEV+2
		rts

		; The callOldxx calls have to pass on to the
		; previous claimant, to do so they must
		;  - stash current vector claimant - it might no longer be us!
		;  - set vectors to "old" claimant
		;  - call the vector
		;  - restore current vector claimant
		;
		; we'll do this in workspace rather than the stack for now
		; investigate speed penalty


callOldWRCHV:	php
		pha
		tya
		pha
		txa
		pha

		lda	zp_mos_genPTR+1
		pha
		lda	zp_mos_genPTR
		pha

		jsr	getWksp				; we're assuming this passes if not all bets are off
		ldy	#PW_CUR_WRCHV
		jsr	saveYWRCHV

		ldy	#PW_OLDC_WRCHV
		jsr	setYWRCHV

		pla
		sta 	zp_mos_genPTR
		pla
		sta 	zp_mos_genPTR+1

		pla
		tax
		pla
		tay
		pla
		plp

		jsr	jmpiWRCHV

		php
		pha
		tya
		pha
		txa
		pha

		lda	zp_mos_genPTR+1
		pha
		lda	zp_mos_genPTR
		pha

		jsr	getWksp				; we're assuming this passes if not all bets are off
		ldy	#PW_CUR_WRCHV
		jsr	setYWRCHV

		pla
		sta 	zp_mos_genPTR
		pla
		sta 	zp_mos_genPTR+1

		pla
		tax
		pla
		tay
		pla
		plp
		rts


jmpiWRCHV:	jmp	(WRCHV)

callOldBYTEV:	php
		pha
		tya
		pha
		txa
		pha

		lda	zp_mos_genPTR+1
		pha
		lda	zp_mos_genPTR
		pha

		jsr	getWksp				; we're assuming this passes if not all bets are off
		ldy	#PW_CUR_BYTEV
		jsr	saveYBYTEV

		ldy	#PW_OLDC_BYTEV
		jsr	setYBYTEV

		pla
		sta 	zp_mos_genPTR
		pla
		sta 	zp_mos_genPTR+1

		pla
		tax
		pla
		tay
		pla
		plp

		jsr	jmpiBYTEV

		php
		pha
		tya
		pha
		txa
		pha

		lda	zp_mos_genPTR+1
		pha
		lda	zp_mos_genPTR
		pha

		jsr	getWksp				; we're assuming this passes if not all bets are off
		ldy	#PW_CUR_BYTEV
		jsr	setYBYTEV

		pla
		sta 	zp_mos_genPTR
		pla
		sta 	zp_mos_genPTR+1

		pla
		tax
		pla
		tay
		pla
		plp
		rts

jmpiBYTEV:	jmp	(BYTEV)

cmdMode15_PAGE:

		ldx	zp_mos_curROM
		lda	swrom_wksp_tab,X
		beq	@notalloc

@already:	jsr	PrintImmed
		.byte	"Mode 15 private workspace already available",13,10,0
		plp
		rts

@notalloc:
		;	mark that next boot should force-allocate a workspace
		lda	#PW_REQ_WKSP
		sta	swrom_wksp_tab,X


		jsr	PrintImmed
		.byte	"Press BREAK to activate",13,10,0
		plp
		rts


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


getWksp:		ldx	zp_mos_curROM		
		lda	swrom_wksp_tab,X
		beq	@retsec
		sta	zp_mos_genPTR+1
		lda	#0
		sta	zp_mos_genPTR
		clc
		rts
@retsec:		sec
		rts


initWksp:	; TODO this probably needs to got in ttx80.asm but leave here for now
		php
		pha
		tya
		pha
		txa
		pha

		lda	zp_mos_genPTR+1
		pha
		lda	zp_mos_genPTR
		pha

		jsr	getWksp
		ldy	#PW_CLAIMED
		lda	#0
		sta	(zp_mos_genPTR),Y		; clear claimed flag

		pla	
		sta	zp_mos_genPTR
		pla	
		sta	zp_mos_genPTR+1

		pla
		tax
		pla
		tay
		pla
		plp
		rts


;------------------------------------------------------------------------------
; Strings and tables
;------------------------------------------------------------------------------

		.SEGMENT "RODATA"
testcard:	.incbin	"testcard.mo15"



