
.macro		VERSION_NAME
		.byte	"TTX80"
.endmacro

		;TODO : move these to autogen'd files? Agree version # with JGH
.macro		VERSION_BYTE
		.byte	0
.endmacro

.macro		VERSION_STRING
		.byte	"0.01"
.endmacro

.macro		VERSION_YEAR
		.byte	"2023"
.endmacro

.macro		VERSION_DATE
		VERSION_YEAR
		.byte	"-02-23"
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

ADDR_ERRBUF	:=	$100				; base of stack!

