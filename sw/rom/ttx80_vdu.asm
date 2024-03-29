
__TTX80_ASM:

		.include "hardware.inc"
		.include "mosrom.inc"
		.include "oslib.inc"
		.include "ttx80_vdu.inc"

		.export	my_WRCHV
		.export my_OSBYTE
		.export  crtcRegs80
		.export  crtcRegsMode0

VDU_TMP1	= zp_vdu_wksp + 0
VDU_TMP2	= zp_vdu_wksp + 1
VDU_TMP3	= zp_vdu_wksp + 2
VDU_TMP4	= zp_vdu_wksp + 3
VDU_TMP5	= zp_vdu_wksp + 4
VDU_TMP6	= zp_vdu_wksp + 5

.exportzp VDU_STATUS		:= $d0

.exportzp VDU_TOP_SCAN		:= $d8
.exportzp VDU_TOP_SCAN_HI	:= $d9

.export OSB_VDU_QSIZE		:= $026a

.export OSB_RAM_PAGES		:= $028e

.export VDU_ADJUST		:= $0290
.export VDU_INTERLACE		:= $0291

.export OSB_HALT_LINES		:= $0269
.export OSB_OUT_STREAM		:= $027c

.export VDU_VARS_BASE		:= $0300
.export VDU_G_WIN_L		:= $0300
.export VDU_G_WIN_L_HI		:= $0301
.export VDU_G_WIN_B		:= $0302
.export VDU_G_WIN_B_HI		:= $0303
.export VDU_G_WIN_R		:= $0304
.export VDU_G_WIN_R_HI		:= $0305
.export VDU_G_WIN_T		:= $0306
.export VDU_G_WIN_T_HI		:= $0307
.export VDU_T_WIN_L		:= $0308
.export VDU_T_WIN_B		:= $0309
.export VDU_T_WIN_R		:= $030a
.export VDU_T_WIN_T		:= $030b

.export VDU_T_CURS_X		:= $0318
.export VDU_T_CURS_Y		:= $0319

.export VDU_QUEUE		:= $031b
.export VDU_QUEUE_1		:= $031c
.export VDU_QUEUE_2		:= $031d
.export VDU_QUEUE_3		:= $031e
.export VDU_QUEUE_4		:= $031f
.export VDU_QUEUE_5		:= $0320
.export VDU_QUEUE_6		:= $0321
.export VDU_QUEUE_7		:= $0322
.export VDU_QUEUE_8		:= $0323

.export VDU_BITMAP_READ		:= $0328

.export VDU_WORKSPACE		:= $0330

.export VDU_CRTC_CUR		:= $034a
.export VDU_CRTC_CUR_HI		:= $034b
.export VDU_T_WIN_SZ		:= $034c
.export VDU_T_WIN_SZ_HI		:= $034d
.export VDU_PAGE		:= $034e
.export VDU_BPC			:= $034f

.export VDU_MEM			:= $0350
.export VDU_MEM_HI		:= $0351
.export VDU_BPR			:= $0352
.export VDU_BPR_HI		:= $0353
.export VDU_MEM_PAGES		:= $0354
.export VDU_MODE		:= $0355
.export VDU_MAP_TYPE		:= $0356

.export VDU_T_FG		:= $0357
.export VDU_T_BG		:= $0358

.export VDU_JUMPVEC		:= $035d
.export VDU_JUMPVEC_HI		:= $035e
.export VDU_CURS_PREV		:= $035f

.export VDU_COL_MASK		:= $0360
.export VDU_PIX_BYTE		:= $0361
.export VDU_MASK_RIGHT		:= $0362
.export VDU_MASK_LEFT		:= $0363
.export VDU_TI_CURS_X		:= $0364
.export VDU_TI_CURS_Y		:= $0365
.export VDU_TTX_CURSOR		:= $0366

SYS_VIA_IORB	:= sheila_SYSVIA_orb
CRTC_ADDRESS	:= sheila_CRTC_reg
CRTC_DATA	:= sheila_CRTC_rw


		.CODE

my_WRCHV:	pha					; Save all registers
		txa					
		pha					
		tya					
		pha					
		bit	sysvar_ECO_OSBW_INTERCEPT	; Check OSWRCH interception flag
		bpl	__no_intercept			; Not set, skip interception call
call_org_vec:
		pla
		tay
		pla
		tax
		pla
		jmp	OSWRCH_NV


__no_intercept:	

		tsx

		clc					; Prepare to not send this to printer
		lda	#$02				; Check output destination
		bit	OSB_OUT_STREAM			; Is VDU driver disabled?
		bne	_BE0C8				; Yes, skip past VDU driver
		lda	$103,X
		jsr	_VDUCHR				; Call VDU driver
			

_BE0C8:
		lda	OSB_OUT_STREAM
		pha
		ora	#$02
		sta	OSB_OUT_STREAM

		lda	$104,X

		jsr	OSWRCH_NV			; TODO: pass on to spool/rs423/printer
							; TODO: this won't work correctly for printer though
							; need to also force printer on if _VDU_CHR returns Cy?
							; TODO: ask on stardot!

		pla
		sta	OSB_OUT_STREAM

		pla
		tay
		pla
		tax
		pla
		rts

_VDUCHR:	
		ldx	OSB_VDU_QSIZE
		bne	_VDUCHR_PASSBACK
		ldx	VDU_MODE			; are we in mode 15
		cpx	#15
		beq	_VDUCHR_MODE15			; jump forwards if we are

		; else check for Q empty and char 22 i.e. mode switch....it might be us!
		cmp	#22
		beq	_VDUCHR_MODE15
_VDUCHR_PASSBACK:
		pla
		pla	; don't return to _BE0C8

		pla
		tay
		pla
		tax
		pla
		jmp	OSWRCH_NV


_VDUCHR_MODE15:	; we are now either in mode 15 or about to do a set mode 
			bit	VDU_STATUS			; else check status byte
			bvc	__vdu_check_delete		; if cursor editing enabled two cursors exist
			jsr	_LC568_swapcurs			; swap values
			jsr	_LCD6A				; then set up write cursor
			bmi	__vdu_check_delete		; if display disabled C4D8
			cmp	#$0d				; else if character in A=RETURN teminate edit
			bne	__vdu_check_delete		; else C4D8

			jsr	_LD918				; terminate edit

__vdu_check_delete:	cmp	#$7f				; is character DELETE ?
			beq	_BC4ED				; if so C4ED

			cmp	#$20				; is it less than space? (i.e. VDU control code)
			bcc	_BC4EF				; if so C4EF
			bit	VDU_STATUS			; else check VDU byte ahain
			bmi	_BC4EA				; if screen disabled C4EA
			jsr	_VDU_OUT_CHAR			; else display a character
			jsr	_VDU_9				; and cursor right
_BC4EA:			jmp	_LC55E				; 

;********* read link addresses and number of parameters *****************

_BC4ED:			lda	#$20				; to replace delete character

;********* read link addresses and number of parameters *****************

_BC4EF:			tay					; Y=A
			lda	_VDU_TABLE_HI,Y			; get hi byte
			
			beq	_VDUCHR_PASSBACK		; not a mode15 special pass to original

			sta	VDU_JUMPVEC_HI

			lda	_VDU_TABLE_LO,Y			; get lo byte of link address
			sta	VDU_JUMPVEC			; store it in jump vector

			lda	_VDU_TABLE_COUNT,Y

			beq	_BC545				; if zero (as it will be if a direct address)
								; there are no parameters needed
								; so C545
			sta	OSB_VDU_QSIZE
			bit	VDU_STATUS			; check if cursor editing enabled
			bvs	_BC52F				; if so re-exchange pointers
			clc					; clear carry
_VDU_0_6_27:
_VDU_0:
_VDU_6:
_VDU_27:		rts					; and exit


_BC52F:			jsr	_LC565				; re-exchange pointers

_BC532:			clc					; carry clear
			rts					; exit


;*********** if explicit link address found, no parameters ***************

_BC545:			tya					; restore A
			cmp	#$08				; is it 7 or less?
			bcc	_BC553				; if so C553
			eor	#$ff				; invert it
			cmp	#$f2				; c is set if A >&0D
			eor	#$ff				; re invert

_BC553:			bit	VDU_STATUS			; VDU status byte
			bmi	_BC580				; if display disabled C580
			php					; push processor flags
			jsr	_VDU_JUMP			; execute required function
			plp					; get back flags
			bcc	_BC561				; if carry clear (from C54B/F)

;**************** main exit routine **************************************

_LC55E:			lda	VDU_STATUS			; VDU status byte
			lsr					; Carry is set if printer is enabled
_BC561:			bit	VDU_STATUS			; VDU status byte
			bvc	_VDU_0_6_27			; if no cursor editing	C511 to exit

;***************** cursor editing routines *******************************

_LC565:			jsr	_LCD7A				; restore normal write cursor

_LC568_swapcurs:			php					; save flags and
			pha					; A
			ldx	#<VDU_T_CURS_X			; X=&18
			ldy	#<VDU_TI_CURS_X			; Y=&64
			jsr	_LCDDE_EXG2_P3			; exchange &300/1+X with &300/1+Y
			jsr	_LCF06				; set up display address
			jsr	SET_CURS_CHARSCANAX				; set cursor position
			lda	VDU_STATUS			; VDU status byte
			eor	#$02				; invert bit 1 to allow or bar scrolling
			sta	VDU_STATUS			; VDU status byte
			pla					; restore flags and A
			plp					; 
			rts					; and exit

_BC580:			eor	#$06				; if A<>6
			bne	_BC58C				; return via C58C
			lda	#$7f				; A=&7F
			bcc	AND_VDU_STATUS			; and goto C5A8 ALWAYS!!

_BC58C:			rts					; and exit

;*************************************************************************
;*									 *
;*	 VDU ROUTINES CRIBBED FROM MOS					 *
;*									 *
;*************************************************************************


OR_VDU_STATUS:		ora	VDU_STATUS			; VDU status byte set bit 0 or bit 7
			bne	STA_VDU_STATUS				; branch forward to store
AND_VDU_STATUS:		and	VDU_STATUS			; VDU status byte clear bit 0 or bit 2 of status
STA_VDU_STATUS:		sta	VDU_STATUS			; VDU status byte
_BC5AC_rts:		rts					; exit


;*************************************************************************
;*									 *
;*	 VDU 8	- CURSOR LEFT						 *
;*									 *
;*************************************************************************

_VDU_8:			dec	VDU_T_CURS_X			; else decrement text column
			ldx	VDU_T_CURS_X			; store new text column
			cpx	VDU_T_WIN_L			; if it is less than text window left
			bmi	__curs_t_wrap_left		; do wraparound	 cursor to rt of screen 1 line up
			lda	VDU_CRTC_CUR			; text cursor 6845 address
			sec					; subtract
			sbc	VDU_BPC				; bytes per character
			tax					; put in X
			lda	VDU_CRTC_CUR_HI			; get text cursor 6845 address
			sbc	#$00				; subtract 0
			cmp	VDU_PAGE			; compare with hi byte of screen RAM address
			bcs	__curs_t_wrap_top		; if = or greater
			adc	VDU_MEM_PAGES			; add screen RAM size hi byte to wrap around
__curs_t_wrap_top:	tay					; Y=A
			jmp	SET_CRTC_CURSeqAX_adj		; A hi and X lo byte of cursor position


;*************************************************************************
;*									 *
;*	 VDU 11 - CURSOR UP						 *
;*									 *
;*************************************************************************

;***************** execute wraparound left-up*****************************

__curs_t_wrap_left:	lda	VDU_T_WIN_R			; text window right
			sta	VDU_T_CURS_X			; text column

;*************** cursor up ***********************************************

_VDU_11:
_BC5F4:			dec	OSB_HALT_LINES			; paged mode counter
			bpl	_BC5FC				; if still greater than 0 skip next instruction
			inc	OSB_HALT_LINES			; paged mode counter to restore X=0
_BC5FC:			ldx	VDU_T_CURS_Y			; current text line
			cpx	VDU_T_WIN_T			; top of text window
			beq	_BC60A				; if its at top of window C60A
			dec	VDU_T_CURS_Y			; else decrement current text line
			jmp	_LC6AF				; and carry on moving cursor

;******** cursor at top of window ****************************************

_BC60A:			clc					; clear carry
			jsr	_LCD3F				; check for window violatations
			lda	#$08				; A=8 to check for software scrolling
			bit	VDU_STATUS			; compare against VDU status byte
			bne	_BC619				; if not enabled C619
			jsr	_LC994				; set screen start register and adjust RAM
			bne	_BC61C				; jump C61C

_BC619:			jsr	_LCDA4				; soft scroll 1 line
_BC61C:			jmp	_LC6AC				; and exit




;*************************************************************************
;*									 *
;*	 VDU 9	- CURSOR RIGHT						 *
;*									 *
;*************************************************************************

_VDU_9:			ldx	VDU_T_CURS_X			; text column
			cpx	VDU_T_WIN_R			; text window right
			bcs	_BC684				; if X exceeds window right then C684
			inc	VDU_T_CURS_X			; text column
			lda	VDU_CRTC_CUR			; text cursor 6845 address
			adc	VDU_BPC				; add bytes per character
			tax					; X=A
			lda	VDU_CRTC_CUR_HI			; text cursor 6845 address
			adc	#$00				; add carry if set
			jmp	SET_CRTC_CURSeqAX_adj		; use AX to set new cursor address

;********: text cursor down and right *************************************

_BC684:			lda	VDU_T_WIN_L			; text window left
			sta	VDU_T_CURS_X			; text column

;*************************************************************************
;*									 *
;*	 VDU 10	 - CURSOR DOWN						 *
;*									 *
;*************************************************************************
_VDU_10:

;********: text cursor down *************************************

_BC68A:			clc					; clear carry
			jsr	_LCAE3				; check bottom margin, X=line count
			ldx	VDU_T_CURS_Y			; current text line
			cpx	VDU_T_WIN_B			; bottom margin
			bcs	_BC69B				; if X=>current bottom margin C69B
			inc	VDU_T_CURS_Y			; else increment current text line
			bcc	_LC6AF				; 
_BC69B:			jsr	_LCD3F				; check for window violations
			lda	#$08				; check bit 3
			bit	VDU_STATUS			; VDU status byte
			bne	_BC6A9				; if software scrolling enabled C6A9
			jsr	_LC9A4				; perform hardware scroll
			bne	_LC6AC				; 
_BC6A9:			jsr	_LCDFF				; execute upward scroll
_LC6AC:			jsr	_LCEAC				; clear a line

_LC6AF:			jsr	_LCF06				; set up display address
			bcc	_BC732				; 


;*************************************************************************
;*									 *
;*	 VDU 28 - DEFINE TEXT WINDOW					 *
;*									 *
;*	 4 parameters							 *
;*									 *
;*************************************************************************
;parameters are set up thus
;0320  P1 left margin
;0321  P2 bottom margin
;0322  P3 right margin
;0323  P4 top margin
;Note that last parameter is always in 0323

_VDU_28:		lda	VDU_QUEUE_6			; get bottom margin
			cmp	VDU_QUEUE_8			; compare with top margin
			bcc	_BC758rts			; if bottom margin exceeds top return
			cmp	#MODE15_TEXT_ROWS-1		; text window bottom margin maximum
			beq	_BC70C				; if equal then its OK
			bcs	_BC758rts			; else exit

_BC70C:			lda	VDU_QUEUE_7			; get right margin
			tay					; put it in Y
			cmp	#MODE15_TEXT_COLS-1		; text window right hand margin maximum
			beq	_BC717				; if equal then OK
			bcs	_BC758rts			; if greater than maximum exit

_BC717:			sec					; set carry to subtract
			sbc	VDU_QUEUE_5			; left margin
			bmi	_BC758rts			; if left greater than right exit
			tay					; else A=Y (window width)
			jsr	_LCA88				; calculate number of bytes in a line
			lda	#$08				; A=8 to set bit  of &D0
			jsr	OR_VDU_STATUS			; indicating that text window is defined
			ldx	#$20				; point to parameters
			ldy	#$08				; point to text window margins
			jsr	_LD48A				; (&300/3+Y)=(&300/3+X)
			jsr	_LCEE8				; set up screen address
			bcs	_VDU_30				; home cursor within window
_BC732:			jmp	SET_CURS_CHARSCANAX				; set cursor position

_BC758rts:		rts	; TODO: merge with another RTS?


;*************************************************************************
;*									 *
;*	 VDU 12 - CLEAR TEXT SCREEN					 *
;*	 CLS								 *
;*									 *
;*************************************************************************

_VDU_12:		lda	VDU_STATUS			; VDU status byte
			and	#$08				; check if software scrolling (text window set)
			bne	_BC767				; if so C767
			jmp	_LCBC1_DOCLS			; initialise screen display and home cursor

_BC767:			ldx	VDU_T_WIN_T			; top of text window
_BC76A:			stx	VDU_T_CURS_Y			; current text line
			jsr	_LCEAC				; clear a line

			ldx	VDU_T_CURS_Y			; current text line
			cpx	VDU_T_WIN_B			; bottom margin
			inx					; X=X+1
			bcc	_BC76A				; if X at compare is less than bottom margin clear next

			; fall through to "HOME"
;*************************************************************************
;*									 *
;*	 VDU 30 - HOME CURSOR						 *
;*									 *
;*************************************************************************

_VDU_30:		lda	#0
			sta	VDU_QUEUE_8			; store 0 in last two parameters
			sta	VDU_QUEUE_7			; 


;*************************************************************************
;*									 *
;*	 VDU 31 - POSITION TEXT CURSOR					 *
;*	 TAB(X,Y)							 *
;*									 *
;*	 2 parameters							 *
;*									 *
;*************************************************************************
;0322 = supplied X coordinate
;0323 = supplied Y coordinate

_VDU_31:		jsr	_LC7A8				; exchange text column/line with workspace 0328/9
			clc					; clear carry
			lda	VDU_QUEUE_7			; get X coordinate
			adc	VDU_T_WIN_L			; add to text window left
			sta	VDU_T_CURS_X			; store as text column
			lda	VDU_QUEUE_8			; get Y coordinate
			clc					; 
			adc	VDU_T_WIN_T			; add top of text window
			sta	VDU_T_CURS_Y			; current text line
			jsr	_LCEE8				; set up screen address
			bcc	_BC732				; set cursor position if C=0 (point on screen)
_LC7A8:			ldx	#<VDU_T_CURS_X			; else point to workspace
			ldy	#<VDU_BITMAP_READ		; and line/column to restore old values
			jmp	_LCDDE_EXG2_P3			; exchange &300/1+X with &300/1+Y

;*************************************************************************
;*									 *
;*	 VDU 13 - CARRIAGE RETURN					 *
;*									 *
;*************************************************************************

_VDU_13:		jsr	_LCE6E				; set text column to left hand column
			jmp	_LC6AF				; set up cursor and display address


;*************************************************************************
;*									 *
;*	 VDU 22 - SELECT MODE						 *
;*	 MODE n								 *
;*									 *
;*	 1 parameter							 *
;*									 *
;*************************************************************************
;parameter in &323

_VDU_22:		lda	VDU_QUEUE_8			; get parameter
			cmp	#15
			bne	@sk22
			jmp	_LCB33

			; a different mode - pass it along
@sk22:			pha
			lda	#22
			jsr	OSWRCH_NV
			pla
			jmp	OSWRCH_NV
			
;********** turn cursor on/off *******************************************
_LC951:			lda	VDU_CURS_PREV			; get last setting of CRT controller register
								; for cursor on
_LC954:			ldy	#$0a				; Y=10 - cursor control register number
			bne	_BC985				; jump to C985, Y=register, Y=value


;********** set CRT controller *******************************************

SET_CRTC_YeqA:		cpy	#$07				; is Y=7
			bcc	_BC985				; if less C985
			bne	_BC967				; else if >7 C967
			adc	VDU_ADJUST			; else ADD screen vertical display adjustment

_BC967:			cpy	#$08				; If Y<>8
			bne	_BC972				; C972
			ora	#$00				; if bit 7 set
			bmi	_BC972				; C972
			eor	VDU_INTERLACE			; else EOR with interlace toggle

_BC972:			cpy	#$0a				; Y=10??
			bne	_BC985				; if not C985
			sta	VDU_CURS_PREV			; last setting of CRT controller register
			tay					; Y=A
			lda	VDU_STATUS			; VDU status byte
			and	#$20				; check bit 5 printing at graphics cursor??
			php					; push flags
			tya					; Y=A
			ldy	#$0a				; Y=10
			plp					; pull flags
			bne	_BC98B				; if graphics in use then C98B


_BC985:			sty	CRTC_ADDRESS			; else set CRTC address register
			sta	CRTC_DATA			; and poke new value to register Y
_BC98B:			rts					; exit


;********** adjust screen RAM addresses **********************************

_LC994:			ldx	VDU_MEM				; window area start address lo
			lda	VDU_MEM_HI			; window area start address hi
			jsr	_LCCF8				; subtract bytes per character row from this
			bcs	_BC9B3				; if no wraparound needed C9B3

			adc	VDU_MEM_PAGES			; screen RAM size hi byte to wrap around
			bcc	_BC9B3				; 

_LC9A4:			ldx	VDU_MEM				; window area start address lo
			lda	VDU_MEM_HI			; window area start address hi
			jsr	_LCAD4				; add bytes per char. row
			bpl	_BC9B3				; 

			sec					; wrap around i other direction
			sbc	VDU_MEM_PAGES			; screen RAM size hi byte
_BC9B3:			sta	VDU_MEM_HI			; window area start address hi
			stx	VDU_MEM				; window area start address lo
			ldy	#$0c				; Y=12
			bne	SET_CRTCY_AXDIV8		; jump to CA0E


;*************************************************************************
;*									 *
;*	 VDU 26 - SET DEFAULT WINDOWS					 *
;*									 *
;*************************************************************************

_VDU_26:		lda	#$00				; A=0
			ldx	#$2c				; X=&2C

_BC9C1:			sta	VDU_G_WIN_L,X			; clear all windows
			dex					; 
			bpl	_BC9C1				; until X=&FF

			ldy	#MODE15_TEXT_COLS-1		; text window right hand margin maximum
			sty	VDU_T_WIN_R			; text window right
			jsr	_LCA88				; calculate number of bytes in a line
			ldy	#MODE15_TEXT_ROWS-1		; text window bottom margin maximum
			sty	VDU_T_WIN_B			; bottom margin

			lda	#24
			jsr	OSWRCH_NV			; and do VDU 24			

			lda	#0
			jsr	OSWRCH_NV			; and do VDU 24			
			jsr	OSWRCH_NV			; and do VDU 24			

			jsr	OSWRCH_NV			; and do VDU 24			
			jsr	OSWRCH_NV			; and do VDU 24			

			lda	#$FF
			jsr	OSWRCH_NV			; and do VDU 24			
			jsr	OSWRCH_NV			; and do VDU 24			

			jsr	OSWRCH_NV			; and do VDU 24			
			jsr	OSWRCH_NV			; and do VDU 24			


			lda	#$f7				; 
			jsr	AND_VDU_STATUS			; clear bit 3 of &D0
			ldx	VDU_MEM				; window area start address lo
			lda	VDU_MEM_HI			; window area start address hi
SET_CRTC_CURSeqAX_adj:	stx	VDU_CRTC_CUR			; text cursor 6845 address
			sta	VDU_CRTC_CUR_HI			; text cursor 6845 address
			bpl	SET_CURS_CHARSCANAX				; set cursor position
			sec					; 
			sbc	VDU_MEM_PAGES			; screen RAM size hi byte

;**************** set cursor position ************************************

SET_CURS_CHARSCANAX:	stx	VDU_TOP_SCAN			; set &D8/9 from X/A
			sta	VDU_TOP_SCAN_HI			; 
			ldx	VDU_CRTC_CUR			; text cursor 6845 address
			lda	VDU_CRTC_CUR_HI			; text cursor 6845 address
			ldy	#$0e				; Y=15
SET_CRTCY_AXDIV8:	sec
			sbc	#$78				; mode 15 0x3000-0x3FFF
			ora	#$30				; EOR with &20
SET_CRTC_YeqAX:		sty	CRTC_ADDRESS			; write to CRTC address file register
			sta	CRTC_DATA			; and to relevant address (register 14)
			iny					; Increment Y
			sty	CRTC_ADDRESS			; write to CRTC address file register
			stx	CRTC_DATA			; and to relevant address (register 15)
			rts					; and RETURN

_LCA88:
			; mode 15 just store as width			iny					; Y=Y+1
			lda	#$00				; Y=0
			sta	VDU_T_WIN_SZ_HI			; text window width hi (bytes)
			iny
			sty	VDU_T_WIN_SZ			; text window width lo (bytes)
			rts					; 



;*************************************************************************
;*									 *
;*	 VDU 127 (&7F) - DELETE (entry 32)				 *
;*									 *
;*************************************************************************

_VDU_127:		jsr	_VDU_8				; cursor left
__vdu_del_mode7:	lda	#' '				; A=&20
			jmp	_VDU_OUT_MODE7			; and return to display a space


;***** Add number of bytes in a line to X/A ******************************

_LCAD4:			pha					; store A
			txa					; A=X
			clc					; clear carry
			adc	VDU_BPR				; bytes per character row
			tax					; X=A
			pla					; get back A
			adc	VDU_BPR_HI			; bytes per character row
			rts					; and return

;********* control scrolling in paged mode *******************************

_BCAE0:			jsr	_LCB14				; zero paged mode line counter
_LCAE3:			
			; DB: a bit of extra pokery required here
			lda	#118
			jsr	OSBYTE				; osbyte 118 check keyboard status; set LEDs
			bcc	_BCAEA				; if carry clear CAEA
			
			; check for shift
			lda	#129
			ldy	#$FF
			ldx	#$FF
			jsr	OSBYTE
			inx
			beq	_BCAE0				; if M set CAE0 do it again

_BCAEA:			lda	VDU_STATUS			; VDU status byte
			eor	#$04				; invert bit 2 paged scrolling
			and	#$46				; and if 2 cursors, paged mode off, or scrolling
			bne	_BCB1C				; barred then CB1C to exit

			lda	OSB_HALT_LINES			; paged mode counter
			bmi	_BCB19				; if negative then exit via CB19

			lda	VDU_T_CURS_Y			; current text line
			cmp	VDU_T_WIN_B			; bottom margin
			bcc	_BCB19				; increment line counter and exit

			lsr					; A=A/4
			lsr					; 
			sec					; set carry
			adc	OSB_HALT_LINES			; paged mode counter
			adc	VDU_T_WIN_T			; top of text window
			cmp	VDU_T_WIN_B			; bottom margin
			bcc	_BCB19				; increment line counter and exit

			clc					; clear carry
_BCB0E:			lda	#118
			jsr	OSBYTE				; osbyte 118 check keyboard status; set LEDs

			; check for shift
			lda	#129
			ldy	#$FF
			ldx	#$FF
			jsr	OSBYTE
			inx

			sec					; set carry
			bne	_BCB0E				; if +ve result then loop till shift pressed

;**************** zero paged mode  counter *******************************

_LCB14:			lda	#$ff				; 
			sta	OSB_HALT_LINES			; paged mode counter
_BCB19:			inc	OSB_HALT_LINES			; paged mode counter
_BCB1C:			rts					; 

; _VDU_22 MODE
;********* enter here from VDU 22,n - MODE *******************************

;    ____  _   ______  __   __  _______  ____  ______   ___________
;   / __ \/ | / / /\ \/ /  /  |/  / __ \/ __ \/ ____/  <  / ____/ /
;  / / / /  |/ / /  \  /  / /|_/ / / / / / / / __/     / /___ \/ /
; / /_/ / /|  / /___/ /  / /  / / /_/ / /_/ / /___    / /___/ /_/
; \____/_/ |_/_____/_/  /_/  /_/\____/_____/_____/   /_/_____(_)

_LCB33:
			tax					; X=mode
			stx	VDU_MODE			; Save current screen MODE
			lda	#0				; Get number of colours -1 for this MODE
			sta	VDU_COL_MASK			; Set current number of logical colours less 1
			sta	VDU_PIX_BYTE			; Set pixels per byte
			lda	#1				; Get bytes/character for this MODE
			sta	VDU_BPC				; Set bytes per character
			sta	VDU_MASK_RIGHT			; colour mask right
			lda	#$80				; byte/pixel=0, this is MODE 7, prepare A=7 offset into mask table
			sta	VDU_MASK_LEFT			; colour mask left
			lda	#4
			sta	VDU_MAP_TYPE			; memory map type
			jsr	_WRITE_SYS_VIA_PORTB		; set hardware scrolling to VIA
			lda	#5
			jsr	_WRITE_SYS_VIA_PORTB		; set hardware scrolling to VIA
			lda	#8				; Screen RAM size hi byte table
			sta	VDU_MEM_PAGES			; screen RAM size hi byte
			lda	#$78				; screen ram address hi byte
			sta	VDU_PAGE			; hi byte of screen RAM address


			lda	#<MODE15_TEXT_COLS		; get nuber of bytes per row from table
			sta	VDU_BPR				; store as bytes per character row
			lda	#>MODE15_TEXT_COLS
			sta	VDU_BPR_HI			; bytes per character row
			lda	#$43				; A=&43
			jsr	AND_VDU_STATUS			; A=A and &D0:&D0=A
			lda	#MODE15_ULA_CTL			; get video ULA control setting
			jsr	VID_ULA_SET			; set video ULA using osbyte 154 code
			php					; push flags
			sei					; set interrupts
			ldy	#11				; Y=11
_BCBB0:			lda	crtcRegs80,Y			; get end of 6845 registers 0-11 table
			jsr	SET_CRTC_YeqA			; set register Y
			dey					; reduce pointers
			bpl	_BCBB0				; and if still >0 do it again
			plp					; pull flags
			lda	#20
			jsr	OSWRCH_NV
			jsr	_VDU_26				; set default windows

_LCBC1_DOCLS:		ldx	#$00				; X=0
			lda	VDU_PAGE			; hi byte of screen RAM address
			stx	VDU_MEM				; window area start address lo
			sta	VDU_MEM_HI			; window area start address hi
			jsr	SET_CRTC_CURSeqAX_adj		; use AX to set new cursor address
			ldy	#$0c				; Y=12
			jsr	SET_CRTC_YeqAX			; set registers 12 and 13 in CRTC
			lda	VDU_T_BG			; background text colour
			ldx	#$00				; X=0
			stx	OSB_HALT_LINES			; paged mode counter
			stx	VDU_T_CURS_X			; text column
			stx	VDU_T_CURS_Y			; current text line
	
@clslp:			sta	$7800,X
			sta	$7900,X
			sta	$7A00,X
			sta	$7B00,X
			sta	$7C00,X
			sta	$7D00,X
			sta	$7E00,X
			sta	$7F00,X
			dex	
			bne	@clslp
			rts

;****************** execute required function ****************************

_VDU_JUMP:		jmp	(VDU_JUMPVEC)			; jump vector set up previously

;********* subtract bytes per line from X/A ******************************

_LCCF8:			pha					; Push A
			txa					; A=X
			sec					; set carry for subtraction
			sbc	VDU_BPR				; bytes per character row
			tax					; restore X
			pla					; and A
			sbc	VDU_BPR_HI			; bytes per character row
			cmp	VDU_PAGE			; hi byte of screen RAM address
_BCD06:			rts					; return


;******** move text cursor to next line **********************************

_LCD3F:			lda	#$02				; A=2 to check if scrolling disabled
			bit	VDU_STATUS			; VDU status byte
			bne	_BCD47				; if scrolling is barred CD47
			bvc	_BCD79				; if cursor editing mode disabled RETURN

_BCD47:			lda	VDU_T_WIN_B			; bottom margin
			bcc	_BCD4F				; if carry clear on entry CD4F
			lda	VDU_T_WIN_T			; else if carry set get top of text window
_BCD4F:			bvs	_BCD59				; and if cursor editing enabled CD59
			sta	VDU_T_CURS_Y			; get current text line
			pla					; pull return link from stack
			pla					; 
			jmp	_LC6AF				; set up cursor and display address

_BCD59:			php					; push flags
			cmp	VDU_TI_CURS_Y			; Y coordinate of text input cursor
			beq	_BCD78				; if A=line count of text input cursor CD78 to exit
			plp					; get back flags
			bcc	_BCD66				; 
			dec	VDU_TI_CURS_Y			; Y coordinate of text input cursor

_BCD65:			rts					; exit

_BCD66:			inc	VDU_TI_CURS_Y			; Y coordinate of text input cursor
			rts					; exit

;*********************** set up write cursor ********************************

_LCD6A:			php					; save flags
			pha					; save A

			lda	VDU_WORKSPACE+8			; so get mode 7 write character cursor character &7F
			sta	(VDU_TOP_SCAN),Y		; store it at top scan line of current character
_LCD77:			pla					; pull A
_BCD78:			plp					; pull flags
_BCD79:			rts					; and exit

_LCD7A:			php					; push flags
			pha					; push A
			ldy	#0
			lda	(VDU_TOP_SCAN),Y		; get cursor from top scan line
			sta	VDU_WORKSPACE+8			; store it
			lda	VDU_TTX_CURSOR			; mode 7 write cursor character
			sta	(VDU_TOP_SCAN),Y		; store it at scan line
			jmp	_LCD77				; and exit



_LCDA4:			jsr	_LCE5B				; exchange line and column cursors with workspace copies
			lda	VDU_T_WIN_B			; bottom margin
			sta	VDU_T_CURS_Y			; current text line
			jsr	_LCF06				; set up display address
_BCDB0:			jsr	_LCCF8				; subtract bytes per character row from this
			bcs	_BCDB8				; wraparound if necessary
			adc	VDU_MEM_PAGES			; screen RAM size hi byte
_BCDB8:			sta	VDU_TMP2			; store A
			stx	VDU_TMP1			; X
			sta	VDU_TMP3			; A again
			bcs	_BCDC6				; if C set there was no wraparound so CDC6
_BCDC0:			jsr	_LCE73				; copy line to new position
								; using (&DA) for read
								; and (&D8) for write
			jmp	_LCDCE				; 

_BCDC6:			jsr	_LCCF8				; subtract bytes per character row from X/A
			bcc	_BCDC0				; if a result is outside screen RAM CDC0
			jsr	_LCE38				; perform a copy

_LCDCE:			lda	VDU_TMP3			; set write pointer from read pointer
			ldx	VDU_TMP1			; 
			sta	VDU_TOP_SCAN_HI			; 
			stx	VDU_TOP_SCAN			; 
			dec	VDU_TMP5			; decrement window height
			bne	_BCDB0				; and if not zero CDB0
_LCDDA_EXG_BMPR_CURS_X:	ldx	#<VDU_BITMAP_READ		; point to workspace
			ldy	#<VDU_T_CURS_X			; point to text column/line
_LCDDE_EXG2_P3:		lda	#$02				; number of bytes to swap
			bne	_BCDE8				; exchange (328/9)+Y with (318/9)+X
								; A=4 to swap X and Y coordinates

;*************** exchange 300/3+Y with 300/3+X ***************************

_LCDE6_EXG4_P3:		lda	#$04				; A =4

;************** exchange (300/300+A)+Y with (300/300+A)+X *****************

_BCDE8:			sta	VDU_TMP1			; store it as loop counter

_BCDEA:			lda	VDU_G_WIN_L,X			; get byte
			pha					; store it
			lda	VDU_G_WIN_L,Y			; get byte pointed to by Y
			sta	VDU_G_WIN_L,X			; put it in 300+X
			pla					; get back A
			sta	VDU_G_WIN_L,Y			; put it in 300+Y
			inx					; increment pointers
			iny					; 
			dec	VDU_TMP1			; decrement loop counter
			bne	_BCDEA				; and if not 0 do it again
			rts					; and exit

;******** execute upward scroll ******************************************


_LCDFF:			jsr	_LCE5B				; exchange line and column cursors with workspace copies
			ldy	VDU_T_WIN_T			; top of text window
			sty	VDU_T_CURS_Y			; current text line
			jsr	_LCF06				; set up display address
_BCE0B:			jsr	_LCAD4				; add bytes per char. row
			bpl	_BCE14				; 
			sec					; 
			sbc	VDU_MEM_PAGES			; screen RAM size hi byte

_BCE14:			sta	VDU_TMP2			; (&DA)=X/A
			stx	VDU_TMP1			; 
			sta	VDU_TMP3			; &DC=A
			bcc	_BCE22				; 
_BCE1C:			jsr	_LCE73				; copy line to new position
								; using (&DA) for read
								; and (&D8) for write
			jmp	_LCE2A				; exit


_BCE22:			jsr	_LCAD4				; add bytes per char. row
			bmi	_BCE1C				; if outside screen RAM CE1C
			jsr	_LCE38				; perform a copy
_LCE2A:			lda	VDU_TMP3			; 
			ldx	VDU_TMP1			; 
			sta	VDU_TOP_SCAN_HI			; 
			stx	VDU_TOP_SCAN			; 
			dec	VDU_TMP5			; decrement window height
			bne	_BCE0B				; CE0B if not 0
			beq	_LCDDA_EXG_BMPR_CURS_X		; exchange text column/linelse CDDA



;*********** copy routines ***********************************************

_LCE38:			ldx	VDU_T_WIN_SZ_HI			; text window width hi (bytes)
			beq	_BCE4D				; if no more than 256 bytes to copy X=0 so CE4D

			ldy	#$00				; Y=0 to set loop counter

_BCE3F:			lda	(VDU_TMP1),Y			; copy 256 bytes
			sta	(VDU_TOP_SCAN),Y		; 
			iny					; 
			bne	_BCE3F				; Till Y=0 again
			inc	VDU_TOP_SCAN_HI			; increment hi bytes
			inc	VDU_TMP2			; 
			dex					; decrement window width
			bne	_BCE3F				; if not 0 go back and do loop again

_BCE4D:			ldy	VDU_T_WIN_SZ			; text window width lo (bytes)
			beq	_BCE5A				; if Y=0 CE5A

_BCE52:			dey					; else Y=Y-1
			lda	(VDU_TMP1),Y			; copy Y bytes
			sta	(VDU_TOP_SCAN),Y		; 
			tya					; A=Y
			bne	_BCE52				; if not 0 CE52
_BCE5A:			rts					; and exit

_LCE5B:			jsr	_LCDDA_EXG_BMPR_CURS_X				; exchange text column/line with workspace
			sec					; set carry
			lda	VDU_T_WIN_B			; bottom margin
			sbc	VDU_T_WIN_T			; top of text window
			sta	VDU_TMP5			; store it
			bne	_LCE6E				; set text column to left hand column
			pla					; get back return address
			pla					; 
			jmp	_LCDDA_EXG_BMPR_CURS_X		; exchange text column/line with workspace

_LCE6E:			lda	VDU_T_WIN_L			; text window left
			bpl	_BCEE3				; Jump CEE3 always!

_LCE73:			lda	VDU_TMP1			; get back A
			pha					; push A
			sec					; set carry
			lda	VDU_T_WIN_R			; text window right
			sbc	VDU_T_WIN_L			; text window left
			sta	VDU_TMP6			; 

			; TODO: can simplify this for 1 BPC!

_BCE7F:			ldy	VDU_BPC				; bytes per character to set loop counter

			dey					; copy loop
_BCE83:			lda	(VDU_TMP1),Y			; 
			sta	(VDU_TOP_SCAN),Y		; 
			dey					; 
			bpl	_BCE83				; 

			ldx	#$02				; X=2
_BCE8C:			clc					; clear carry
			lda	VDU_TOP_SCAN,X			; 
			adc	VDU_BPC				; bytes per character
			sta	VDU_TOP_SCAN,X			; 
			lda	VDU_TOP_SCAN_HI,X		; 
			adc	#$00				; 
			bpl	_BCE9E				; if this remains in screen RAM OK

			sec					; else wrap around screen
			sbc	VDU_MEM_PAGES			; screen RAM size hi byte
_BCE9E:			sta	VDU_TOP_SCAN_HI,X		; 
			dex					; X=X-2
			dex					; 
			beq	_BCE8C				; if X=0 adjust second set of pointers
			dec	VDU_TMP6			; decrement window width
			bpl	_BCE7F				; and if still +ve do it all again
			pla					; get back A
			sta	VDU_TMP1			; and store it
			rts					; then exit



;*********** clear a line ************************************************

_LCEAC:			lda	VDU_T_CURS_X			; text column
			pha					; save it
			jsr	_LCE6E				; set text column to left hand column
			jsr	_LCF06				; set up display address
			sec					; set carry
			lda	VDU_T_WIN_R			; text window right
			sbc	VDU_T_WIN_L			; text window left
			sta	VDU_TMP3			; save for later
			ldy	#0				; 
_BCEBF:			lda	VDU_T_BG			; background text colour
_BCEC5:			sta	(VDU_TOP_SCAN),Y		; store background colour at this point on screen
			inc	VDU_TOP_SCAN
			bne	_BCEDA
			inc	VDU_TOP_SCAN_HI			; get hi byte
			bpl	_BCEDA				; if +ve CeDA
			lda	VDU_TOP_SCAN_HI			; get hi byte
			sec					; else wrap around
			sbc	VDU_MEM_PAGES			; screen RAM size hi byte
			sta	VDU_TOP_SCAN_HI			; 
_BCEDA:			dec	VDU_TMP3			; decrement window width
			bpl	_BCEBF				; ind if not 0 do it all again
			pla					; get back A
_BCEE3:			sta	VDU_T_CURS_X			; restore text column
_BCEE6:			sec					; set carry
			rts					; and exit



_LCEE8:			ldx	VDU_T_CURS_X			; text column
			cpx	VDU_T_WIN_L			; text window left
			bmi	_BCEE6				; if less than left margin return with carry set
			cpx	VDU_T_WIN_R			; text window right
			beq	_BCEF7				; if equal to right margin thats OK
			bpl	_BCEE6				; if greater than right margin return with carry set

_BCEF7:			ldx	VDU_T_CURS_Y			; current text line
			cpx	VDU_T_WIN_T			; top of text window
			bmi	_BCEE6				; if less than top margin
			cpx	VDU_T_WIN_B			; bottom margin
			beq	_LCF06				; set up display address
			bpl	_BCEE6				; or greater than bottom margin return with carry set
			
			; drop through to display address

;************:set up display address *************************************

; Mode 15 is assumed so just mulx80

_LCF06:			lda	VDU_T_CURS_Y			; current text line
			asl					; A=A*2
			tay					; Y=A			
			clc
			lda	_MUL80,Y			; get CRTC multiplication table pointer
			adc	VDU_MEM
			sta	VDU_TOP_SCAN
			lda	_MUL80+1,Y
			adc	VDU_MEM_HI
			sta	VDU_TOP_SCAN_HI			; &D9=A
			tay					; 
			lda	VDU_T_CURS_X			; text column
			clc					; clear carry
			adc	VDU_TOP_SCAN			; add to &D8
			sta	VDU_TOP_SCAN			; and store it
			sta	VDU_CRTC_CUR			; text cursor 6845 address
			tax					; X=A
			tya					; A=Y
			adc	#$00				; Add carry if set
			sta	VDU_CRTC_CUR_HI			; text cursor 6845 address
			bpl	_BCF59				; if less than &800 goto &CF59
			sec					; else wrap around
			sbc	VDU_MEM_PAGES			; screen RAM size hi byte
_BCF59:			sta	VDU_TOP_SCAN_HI			; store in high byte
			clc					; clear carry
			rts					; and exit returning cursor HI in X!

;************* Character rendering routine *******************
_VDU_OUT_CHAR:		
_VDU_OUT_MODE7:		ldy	#$02				; Y=2
__mode7_xlate_loop:	cmp	_TELETEXT_CHAR_TAB,Y		; compare with teletext conversion table
			beq	__mode7_xlate_char		; if equal then CFE9
			dey					; else Y=Y-1
			bpl	__mode7_xlate_loop		; and if +ve CFDE

__mode7_out_char:	ldx	#0
			sta	(VDU_TOP_SCAN,X)		; if not write byte to screen
			rts					; and exit

__mode7_xlate_char:	lda	_TELETEXT_CHAR_TAB+1,Y		; convert with teletext conversion table
			bne	__mode7_out_char		; and write it



_LD486:			ldy	#$28				; copy 4 bytes from 324/7 to 328/B
_LD488:			ldx	#$24				; 
_LD48A:			lda	#$04				; 


;***********copy A bytes from 300,X to 300,Y ***************************

_VDU_VAR_COPY:		sta	VDU_TMP1			; 
__vdu_var_copy_next:	lda	VDU_G_WIN_L,X			; 
			sta	VDU_G_WIN_L,Y			; 
			inx					; 
			iny					; 
			dec	VDU_TMP1			; 
			bne	__vdu_var_copy_next		; 
			rts					; and return

_LD918:			lda	#$bd				; zero bits 2 and 6 of VDU status
			jsr	AND_VDU_STATUS				; 
			jsr	_LC951				; set normal cursor
			lda	#$0d				; A=&0D
			rts					; and return


;*******Set Video ULA control register **entry from VDU routines **************
				; called from &CBA6, &DD37

VID_ULA_SET:		pha
			txa
			pha
			tya
			pha
			tsx
			lda	$103,X
			tax
			lda	#154
			jsr	OSBYTE
			pla
			tay
			pla
			tax
			pla
			rts					; and return

;****************** Write A to SYSTEM VIA register B *************************
				; called from &CB6D, &CB73
_WRITE_SYS_VIA_PORTB:	php					; push flags
			sei					; disable interupts
			sta	SYS_VIA_IORB			; write register B from Accumulator
			plp					; get back flags
			rts					; and exit

;;    ____  _____ ______  ______________   ____  __________  ________  __________________
;;   / __ \/ ___// __ ) \/ /_  __/ ____/  / __ \/ ____/ __ \/  _/ __ \/ ____/ ____/_  __/
;;  / / / /\__ \/ __  |\  / / / / __/    / /_/ / __/ / / / // // /_/ / __/ / /     / /
;; / /_/ /___/ / /_/ / / / / / / /___   / _, _/ /___/ /_/ // // _, _/ /___/ /___  / /
;; \____//____/_____/ /_/ /_/ /_____/  /_/ |_/_____/_____/___/_/ |_/_____/\____/ /_/
;; 

my_OSBYTE:		cmp	#133
			beq	_OSBYTE_133
			cmp	#132
			beq	_OSBYTE_132

SKIP_OSBYTE:		jmp	MOS_BYTEV_ORG


;*************************************************************************
;*									 *
;*	 OSBYTE 132 - READ BOTTOM OF DISPLAY RAM			 *
;*									 *
;*************************************************************************

_OSBYTE_132:		ldx	VDU_MODE			; Get current screen mode

;*************************************************************************
;*									 *
;*	 OSBYTE 133 - READ LOWEST ADDRESS FOR GIVEN MODE		 *
;*									 *
;*************************************************************************

_OSBYTE_133:		
			cpx	#15
			bne	SKIP_OSBYTE

			ldx	#0
			ldy	#$78
			bit	OSB_RAM_PAGES
			bmi	@sk2
			ldy	#$38
@sk2:			rts



		.RODATA


_VDU_TABLE_LO:		.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	<_VDU_8
			.byte	<_VDU_9
			.byte	<_VDU_10
			.byte	<_VDU_11
			.byte	<_VDU_12
			.byte	<_VDU_13
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	0
			.byte	<_VDU_22
			.byte	0
			.byte	0
			.byte	0
			.byte	<_VDU_26
			.byte	0
			.byte	<_VDU_28
			.byte	0
			.byte	<_VDU_30
			.byte	<_VDU_31
			.byte	<_VDU_127

_VDU_TABLE_HI:		.byte	0				; VDU  0   - &C511, no parameters
			.byte	0				; VDU  1   - &C53B, 1 parameter
			.byte	0				; VDU  2   - &C596, no parameters
			.byte	0				; VDU  3   - &C5A1, no parameters
			.byte	0				; VDU  4   - &C5AD, no parameters
			.byte	0				; VDU  5   - &C5B9, no parameters
			.byte	0				; VDU  6   - &C511, no parameters
			.byte	0				; VDU  7   - &E86F, no parameters
			.byte	>_VDU_8				; VDU  8   - &C5C5, no parameters
			.byte	>_VDU_9				; VDU  9   - &C664, no parameters
			.byte	>_VDU_10				; VDU 10  - &C6F0, no parameters
			.byte	>_VDU_11				; VDU 11  - &C65B, no parameters
			.byte	>_VDU_12				; VDU 12  - &C759, no parameters
			.byte	>_VDU_13				; VDU 13  - &C7AF, no parameters
			.byte	0					; VDU 14  - &C58D, no parameters
			.byte	0					; VDU 15  - &C5A6, no parameters
			.byte	0					; VDU 16  - &C7C0, no parameters
			.byte	0					; VDU 17  - &C7F9, 1 parameter
			.byte	0					; VDU 18  - &C7FD, 2 parameters
			.byte	0					; VDU 19  - &C892, 5 parameters
			.byte	0					; VDU 20  - &C839, no parameters
			.byte	0					; VDU 21  - &C59B, no parameters
			.byte	>_VDU_22				; VDU 22  - &C8EB, 1 parameter
			.byte	0					; VDU 23  - &C8F1, 9 parameters
			.byte	0					; VDU 24  - &CA39, 8 parameters
			.byte	0					; VDU 25  - &C9AC, 5 parameters
			.byte	>_VDU_26				; VDU 26  - &C9BD, no parameters
			.byte	0					; VDU 27  - &C511, no parameters
			.byte	>_VDU_28				; VDU 28  - &C6FA, 4 parameters
			.byte	0					; VDU 29  - &CAA2, 4 parameters
			.byte	>_VDU_30				; VDU 30  - &C779, no parameters
			.byte	>_VDU_31				; VDU 31  - &C787, 2 parameters
			.byte	>_VDU_127			; VDU 127 - &CAAC, no parameters

_VDU_TABLE_COUNT:		.byte	<0				; VDU  0  - &C511, no parameters
			.byte	<-1				; VDU  1  - &C53B, 1 parameter
			.byte	<0				; VDU  2  - &C596, no parameters
			.byte	<0				; VDU  3  - &C5A1, no parameters
			.byte	<0				; VDU  4  - &C5AD, no parameters
			.byte	<0				; VDU  5  - &C5B9, no parameters
			.byte	<0				; VDU  6  - &C511, no parameters
			.byte	<0				; VDU  7  - &E86F, no parameters
			.byte	<0				; VDU  8  - &C5C5, no parameters
			.byte	<0				; VDU  9  - &C664, no parameters
			.byte	<0				; VDU 10  - &C6F0, no parameters
			.byte	<0				; VDU 11  - &C65B, no parameters
			.byte	<0				; VDU 12  - &C759, no parameters
			.byte	<0				; VDU 13  - &C7AF, no parameters
			.byte	<0				; VDU 14  - &C58D, no parameters
			.byte	<0				; VDU 15  - &C5A6, no parameters
			.byte	<0				; VDU 16  - &C7C0, no parameters
			.byte	<-1				; VDU 17  - &C7F9, 1 parameter
			.byte	<-2				; VDU 18  - &C7FD, 2 parameters
			.byte	<-5				; VDU 19  - &C892, 5 parameters
			.byte	<0				; VDU 20  - &C839, no parameters
			.byte	<0				; VDU 21  - &C59B, no parameters
			.byte	<-1				; VDU 22  - &C8EB, 1 parameter
			.byte	<0				; VDU 23  - &C8F1, 9 parameters
			.byte	<0				; VDU 24  - &CA39, 8 parameters
			.byte	<0				; VDU 25  - &C9AC, 5 parameters
			.byte	<0				; VDU 26  - &C9BD, no parameters
			.byte	<0				; VDU 27  - &C511, no parameters
			.byte	<-4				; VDU 28  - &C6FA, 4 parameters
			.byte	<0				; VDU 29  - &CAA2, 4 parameters
			.byte	<0				; VDU 30  - &C779, no parameters
			.byte	<-2				; VDU 31  - &C787, 2 parameters
			.byte	<0				; VDU 127 - &CAAC, no parameters

	; TODO make this smaller as a mulx10 and do lsr's?
_MUL80:
			.word	0*80
			.word	1*80
			.word	2*80
			.word	3*80
			.word	4*80
			.word	5*80
			.word	6*80
			.word	7*80
			.word	8*80
			.word	9*80
			.word	10*80
			.word	11*80
			.word	12*80
			.word	13*80
			.word	14*80
			.word	15*80
			.word	16*80
			.word	17*80
			.word	18*80
			.word	19*80
			.word	20*80
			.word	21*80
			.word	22*80
			.word	23*80
			.word	24*80



crtcRegs80:	.byte $7F,$50,$62,$28,$1E,$02,$19,$1B,$93,$12,$72,$13,$30,$00

crtcRegsMode0:	.byte $7F,$50,$62,$28,$26,$00,$20,$22,$01,$07,$67,$08,$06,$00

;*********** TELETEXT CHARACTER CONVERSION TABLE  ************************

_TELETEXT_CHAR_TAB:	.byte	$23				; '#' -> '_'
			.byte	$5f				; '_' -> '`'
			.byte	$60				; '`' -> '#'
			.byte	$23				; '#'
