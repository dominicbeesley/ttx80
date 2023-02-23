
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


;*************************************************************************
;*									 *
;*	 VDU ROUTINES CRIBBED FROM MOS					 *
;*									 *
;*************************************************************************




;*************************************************************************
;*									 *
;*	 VDU 8	- CURSOR LEFT						 *
;*									 *
;*************************************************************************

_VDU_8:			jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	_BC61F				; move cursor left 8 pixels if graphics
			dec	VDU_T_CURS_X			; else decrement text column
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

_VDU_11:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC5F4				; if text cursor then C5F4
_BC660:			ldx	#$02				; else X=2
			bne	_BC6B6				; goto C6B6

;*************************************************************************
;*									 *
;*	 VDU 9	- CURSOR RIGHT						 *
;*									 *
;*************************************************************************

_VDU_9:			lda	VDU_STATUS			; VDU status byte
			and	#$20				; check bit 5
			bne	_BC6B4				; if set then graphics cursor in use so C6B4
			ldx	VDU_T_CURS_X			; text column
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
;*	 VDU 10	 - CURSOR DOWN						 *
;*									 *
;*************************************************************************

_VDU_10:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC68A				; if text cursor back to C68A
_BC6F5:			ldx	#$02				; else X=2 to indicate vertical movement
			jmp	_LC621				; move graphics cursor down

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

_VDU_28:		ldx	VDU_MODE			; screen mode
			lda	VDU_QUEUE_6			; get bottom margin
			cmp	VDU_QUEUE_8			; compare with top margin
			bcc	_BC758				; if bottom margin exceeds top return
			cmp	_TEXT_ROW_TABLE,X		; text window bottom margin maximum
			beq	_BC70C				; if equal then its OK
			bcs	_BC758				; else exit

_BC70C:			lda	VDU_QUEUE_7			; get right margin
			tay					; put it in Y
			cmp	_TEXT_COL_TABLE,X		; text window right hand margin maximum
			beq	_BC717				; if equal then OK
			bcs	_BC758				; if greater than maximum exit

_BC717:			sec					; set carry to subtract
			sbc	VDU_QUEUE_5			; left margin
			bmi	_BC758				; if left greater than right exit
			tay					; else A=Y (window width)
			jsr	_LCA88				; calculate number of bytes in a line
			lda	#$08				; A=8 to set bit  of &D0
			jsr	OR_VDU_STATUS				; indicating that text window is defined
			ldx	#$20				; point to parameters
			ldy	#$08				; point to text window margins
			jsr	_LD48A				; (&300/3+Y)=(&300/3+X)
			jsr	_LCEE8				; set up screen address
			bcs	_VDU_30				; home cursor within window
_BC732:			jmp	SET_CURS_CHARSCANAX				; set cursor position


;*************************************************************************
;*									 *
;*	 VDU 12 - CLEAR TEXT SCREEN					 *
;*	 CLS								 *
;*									 *
;*************************************************************************

_VDU_12:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	_BC7BD				; if graphics cursor &C7BD
			lda	VDU_STATUS			; VDU status byte
			and	#$08				; check if software scrolling (text window set)
			bne	_BC767				; if so C767
			jmp	_LCBC1_DOCLS				; initialise screen display and home cursor

_BC767:			ldx	VDU_T_WIN_T			; top of text window
_BC76A:			stx	VDU_T_CURS_Y			; current text line
			jsr	_LCEAC				; clear a line

			ldx	VDU_T_CURS_Y			; current text line
			cpx	VDU_T_WIN_B			; bottom margin
			inx					; X=X+1
			bcc	_BC76A				; if X at compare is less than bottom margin clear next


;*************************************************************************
;*									 *
;*	 VDU 30 - HOME CURSOR						 *
;*									 *
;*************************************************************************

_VDU_30:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC781				; if text cursor C781
			jmp	_LCFA6				; home graphic cursor if graphic
_BC781:			sta	VDU_QUEUE_8			; store 0 in last two parameters
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

_VDU_31:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	_BC758				; exit
			jsr	_LC7A8				; exchange text column/line with workspace 0328/9
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
			jmp	_LCDDE_EXG2_P3				; exchange &300/1+X with &300/1+Y

;*************************************************************************
;*									 *
;*	 VDU 13 - CARRIAGE RETURN					 *
;*									 *
;*************************************************************************

_VDU_13:		jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			beq	_BC7B7				; if text C7B7
			jmp	_LCFAD				; else set graphics cursor to left hand columm

_BC7B7:			jsr	_LCE6E				; set text column to left hand column
			jmp	_LC6AF				; set up cursor and display address

_BC7BD:			jsr	_LCFA6				; home graphic cursor


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
			jmp	_LCB33				; goto CB33

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

			ldx	VDU_MODE			; screen mode
			ldy	_TEXT_COL_TABLE,X		; text window right hand margin maximum
			sty	VDU_T_WIN_R			; text window right
			jsr	_LCA88				; calculate number of bytes in a line
			ldy	_TEXT_ROW_TABLE,X		; text window bottom margin maximum
			sty	VDU_T_WIN_B			; bottom margin
			ldy	#$03				; Y=3
			sty	VDU_QUEUE_8			; set as last parameter
			iny					; increment Y
			sty	VDU_QUEUE_6			; set parameters
			dec	VDU_QUEUE_7			; 
			dec	VDU_QUEUE_5			; 
			jsr	_VDU_24				; and do VDU 24
			lda	#$f7				; 
			jsr	AND_VDU_STATUS				; clear bit 3 of &D0
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
SET_CRTCY_AXDIV8:	pha					; Push A
			lda	VDU_MODE			; screen mode
			cmp	#$07				; is it mode 7?
			pla					; get back A
			bcs	_BCA27				; if mode 7 selected CA27
			stx	VDU_TMP1			; else store X
			lsr					; divide X/A by 8
			ror	VDU_TMP1			; 
			lsr					; 
			ror	VDU_TMP1			; 
			lsr					; 
			ror	VDU_TMP1			; 
			ldx	VDU_TMP1			; 
			jmp	SET_CRTC_YeqAX			; goto CA2B

_BCA27:			sbc	#$74				; mode 7 subtract &74
			eor	#$20				; EOR with &20
SET_CRTC_YeqAX:		sty	CRTC_ADDRESS			; write to CRTC address file register
			sta	CRTC_DATA			; and to relevant address (register 14)
			iny					; Increment Y
			sty	CRTC_ADDRESS			; write to CRTC address file register
			stx	CRTC_DATA			; and to relevant address (register 15)
			rts					; and RETURN

;*************************************************************************
;*									 *
;*	 VDU 127 (&7F) - DELETE (entry 32)				 *
;*									 *
;*************************************************************************

_VDU_127:		jsr	_VDU_8				; cursor left
			jsr	_LC588				; A=0 if text cursor A=&20 if graphics cursor
			bne	__vdu_del_modeX			; if graphics then CAC7
			ldx	VDU_COL_MASK			; number of logical colours less 1
			beq	__vdu_del_mode7			; if mode 7 CAC2
			sta	VDU_TMP5			; else store A (always 0)
			lda	#$c0				; A=&C0
			sta	VDU_TMP6			; store in &DF (&DE) now points to C300 SPACE pattern
			jmp	_LCFBF				; display a space

__vdu_del_mode7:	lda	#$20				; A=&20
			jmp	_VDU_OUT_MODE7			; and return to display a space

__vdu_del_modeX:	lda	#$7f				; for graphics cursor
			jsr	_LD03E				; set up character definition pointers
			ldx	VDU_G_BG			; Background graphics colour
			ldy	#$00				; Y=0
			jmp	_LCF63				; invert pattern data (to background colour)

;***** Add number of bytes in a line to X/A ******************************

_LCAD4:			pha					; store A
			txa					; A=X
			clc					; clear carry
			adc	VDU_BPR				; bytes per character row
			tax					; X=A
			pla					; get back A
			adc	VDU_BPR_HI			; bytes per character row
			rts					; and return



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
			.byte	<-9				; VDU 23  - &C8F1, 9 parameters
			.byte	<-8				; VDU 24  - &CA39, 8 parameters
			.byte	<-5				; VDU 25  - &C9AC, 5 parameters
			.byte	<0				; VDU 26  - &C9BD, no parameters
			.byte	<0				; VDU 27  - &C511, no parameters
			.byte	<-4				; VDU 28  - &C6FA, 4 parameters
			.byte	<-4				; VDU 29  - &CAA2, 4 parameters
			.byte	<0				; VDU 30  - &C779, no parameters
			.byte	<-2				; VDU 31  - &C787, 2 parameters
			.byte	<0				; VDU 127 - &CAAC, no parameters


crtcRegs80:	.byte $7F,$50,$62,$28,$1E,$02,$19,$1B,$93,$12,$72,$13,$30,$00

crtcRegsMode0:	.byte $7F,$50,$62,$28,$26,$00,$20,$22,$01,$07,$67,$08,$06,$00