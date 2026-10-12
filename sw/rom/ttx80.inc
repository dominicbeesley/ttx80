
	.import __SWRAM_WKSP_LOAD__

.macro		VERSION_NAME
		.byte	"TTX80"
.endmacro

		;TODO : move these to autogen'd files? Agree version # with JGH
.macro		VERSION_BYTE
		.byte	0
.endmacro

.macro		VERSION_STRING
		.byte	"0.02"
.endmacro

.macro		VERSION_YEAR
		.byte	"2026"
.endmacro

.macro		VERSION_DATE
		VERSION_YEAR
		.byte	"-10-12"
.endmacro

.macro		M_ERROR
		jsr	BounceErrorOffStack
.endmacro

.macro		TODO	error
		M_ERROR
		.byte	$FF
		.byte	error
		.byte	0
.endmacro

.macro		SJTE	serv, addr
		.byte	serv
		.byte	>(addr - 1)			; bytes here in order ready to be stacked then rts'd to
		.byte 	<(addr - 1)
.endmacro


zp_trans_tmp	:=	$A8				; transient command buffer
zp_trans_acc	:=	$AC				; 4 byte accumulator used in hex parsers
zp_tmp_ptr		:=	$AC				; !! NOTE: overlaps acc


; Private workspace byte at DF0,X 
; 	%11xxxxxx	- allocated from Hazel
;	%10xxxxxx	- sideways RAM detected
;	%00xxxxxx	- low RAM allocated so long as not 0
;   %01xxxxxx	- request pending

PW_SWRAM		:= __SWRAM_WKSP_LOAD__
PW_REQ_WKSP		:= $40				; indicate to SVC 24/2 that we want workspace
									; this set by *MODE16 PAGE
PW_CLAIMED			:= $00			; if non-zero we've claimed
PW_OLDC_WRCHV		:= $01			; existing claimant before us, pass on to this
PW_OLDC_EXTWRCHV	:= $03			; existing extended claimant before us, pass on to this
PW_OLDC_BYTEV		:= $06			; existing claimant before us, pass on to this
PW_OLDC_EXTBYTEV	:= $08			; existing extended claimant before us, pass on to this

				; temp saves during a pass-on
PW_CUR_WRCHV		:= $0B
PW_CUR_EXTWRCHV		:= $0D
PW_CUR_BYTEV		:= $10
PW_CUR_EXBYTEV		:= $12

PW_OFFS_TEST	:= $A5				; use this offset from private workspace to test
									; write-ability at boot time (can be shared with
									; anything that doesn't need to survive reset)

ADDR_ERRBUF	:=	$100				; base of stack!

