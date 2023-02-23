		.include "mosrom.inc"	
		.include "oslib.inc"

		.include "ttx80.inc"
		.include "ttx80_utils.inc"

		.import 	cmdMode15
		.import  cmdTTX80TEST



		.export	Copyright

		.export ServiceOut
		.export ServiceOutA0
		.export str_Dossy

		.SEGMENT "CODE_ROMHEADER"


; this contains the rom header and service routines and help/strings

code_base:		

;		ORG	$8000

		.byte	0,0,0				; language entry
		jmp	Service				; service entry
		.byte	$82				; not a language, 6502 code
		.byte	Copyright-code_base
		VERSION_BYTE	
utils_name:
		VERSION_NAME
		.byte	0
		VERSION_STRING
		.byte	" ("
		VERSION_DATE
		.byte	")"
Copyright:
		.byte	0
		.byte	"(C)"
		VERSION_YEAR
		.byte	" "
str_Dossy:	.byte   "Dossytronics"
		.byte	0

		.CODE


;* ---------------- 
;* SERVICE ROUTINES
;* ----------------
	;TODO make this relative!
Serv_jump_table:
		SJTE	$01, svc1_ClaimAbs
		SJTE	$04, svc4_COMMAND
		SJTE	$09, svc9_HELP
Serv_jump_table_Len	:= 	* - Serv_jump_table	


Service:
		; preserve Y,A (X can be determined from &F4)		
		pha
		tax
		tya
		pha
		txa
		ldx	#0
@1:		cmp	Serv_jump_table,X
		beq	ServMatch
		inx
		inx
		inx		
		cpx	#Serv_jump_table_Len
		bcc	@1
		bcs	ServiceOut
ServMatch:	inx
		lda	Serv_jump_table,X
		pha
		lda	Serv_jump_table+1,X
		pha
		rts					; jump to service routine


ServiceOut:	ldx	zp_mos_curROM
		pla
		tay
		pla					; pass to other service routines
		rts
ServiceOutA0:	ldx	zp_mos_curROM
		pla
		tay
		pla
		lda	#0				; Don't pass to other service routines
		rts


; -------------------------------
; SERVICE 1 - Claim Abs Workspace
; -------------------------------
; - We don't need/want abs workspace but will claim vectors here
;   SRNUKE

svc1_ClaimAbs:
		jmp	ServiceOut


; -----------------
; SERVICE 9 - *Help
; -----------------
; help string is at (&F2),Y
svc9_HELP:
		lda	zp_mos_txtptr
		sta	zp_tmp_ptr
		lda	zp_mos_txtptr + 1
		sta	zp_tmp_ptr + 1

		jsr	SkipSpacesPTR
		cmp	#$D
		beq	svc9_HELP_nokey

svc9_keyloop:
		; keywords were included scan for our key
		ldx	#0
@1:		inx
		lda	(zp_tmp_ptr),Y
		iny
		jsr	ToUpper				; to upper
		cmp	str_HELP_KEY-1,X	
		beq	@1
		cmp	#'.'
		beq	svc9_helptable
		cmp	#' '+1
		bcc	@keyend2			; <' ' - at end of keywords (on command line)
@3:		lda	(zp_tmp_ptr),Y			; not at end skip forwards to next space or lower
		iny
		cmp	#' '+1
		bcs	@3
		dey					; move back one to point at space or lower
		jsr	SkipSpacesPTR
		cmp	#$D				
		bne	@keyend
		jmp	svc9_HELP_exit			; end of command line, done
@keyend2:	dey
@keyend:	lda	str_HELP_KEY-1,X
		beq	svc9_helptable			; at end of keyword show table
		jsr	SkipSpacesPTR			; try another
		cmp	#$D
		beq	svc9_HELP_exit
		bne	svc9_keyloop

svc9_helptable:	
		jsr	svc9_HELP_showbanner
		; got a match, dump out our commands help
		ldx	#0
@1:		ldy	tbl_commands+1,X		; get hi byte of string
		beq	svc9_HELP_exit			; if zero at end of table
		jsr	PrintSpc
		jsr	PrintSpc
		txa
		pha
		lda	tbl_commands,X			; lo byte
		tax
		jsr	PrintXY
		jsr	PrintSpc
		pla
		tax
		inx
		inx
		inx
		inx					; point at help args string
		ldy	tbl_commands+1,X		; hi byte of args string
		beq	@2
		txa
		pha
		lda	tbl_commands,X
		tax
		jsr	PrintXY
		pla
		tax
@2:		jsr	PrintNL
		inx
		inx
		bne	@1


svc9_HELP_nokey:
		jsr	svc9_HELP_showbanner
svc9_HELP_exit:	jmp	ServiceOut


svc9_HELP_showbanner:
		jsr	PrintNL
		lda	#<utils_name
		sta	zp_tmp_ptr
		lda	#>utils_name			; point at name, version, copyright strings
		sta	zp_tmp_ptr+1
		lda	#2
		sta	zp_trans_tmp
		ldy	#0
@1:		jsr	PrintPTR
		jsr	PrintSpc
		dec	zp_trans_tmp
		bne	@1

		jmp	PrintNL


		

; --------------------
; SERVICE 4 - *COMMAND
; --------------------

svc4_COMMAND:	; scan command table for commands

		; save begining of command pointer
		tya
		pha

		lda	#<tbl_commands
		sta	zp_mos_genPTR
		lda	#>tbl_commands
		sta	zp_mos_genPTR + 1


cmd_loop:	pla
		pha
		tay					; restore zp_mos_txtptr and Y from stack
		jsr	SkipSpacesPTR
		sty	zp_mos_error_ptr + 1		; we have to subtract the start Y from the string pointer!
		ldy	#0
		sec
		lda	(zp_mos_genPTR),Y
		sbc	zp_mos_error_ptr + 1
		sta	zp_mos_error_ptr
		iny
		lda	(zp_mos_genPTR),Y		
		beq	svc4_CMD_exit			; no more commands
		sbc	#0
		ldy	zp_mos_error_ptr+1		; get back Y
		sta	zp_mos_error_ptr+1		; point to command name - Y
		dey
@cmd_match_lp:	iny
		lda	(zp_mos_txtptr),Y
		jsr	ToUpper
		cmp	(zp_mos_error_ptr),Y
		beq	@cmd_match_lp
		lda	(zp_mos_error_ptr),Y		; command name finished
		beq	@cmd_match_sk
@cmd_match_nxt:	lda	zp_mos_genPTR
		clc
		adc	#6
		sta	zp_mos_genPTR
		bcc	cmd_loop			; try next table entry
		inc	zp_mos_genPTR+1
		bne	cmd_loop

@cmd_match_sk:	lda	(zp_mos_txtptr),Y
		cmp	#' '+1
		bcs	@cmd_match_nxt		

svc4_CMD_exec:	pla					; discard stacked y
		; push address of ServiceOutA0 to stack for return
		lda	#>(ServiceOutA0-1)
		pha
		lda	#<(ServiceOutA0-1)
		pha
		sty	zp_mos_error_ptr
		; push address of Command Routine to stack for rts
		ldy	#3
		lda	(zp_mos_genPTR),Y
		pha
		dey
		lda	(zp_mos_genPTR),Y
		pha
		ldy	zp_mos_error_ptr
		rts					; execute command


svc4_CMD_exit:	pla					; discard stacked Y
		jmp	ServiceOut




		.SEGMENT "RODATA"


tbl_commands:		.word	strMode15, cmdMode15-1, helpMode15
			.word	strTTX80TEST, cmdTTX80TEST-1, 0
			.word	0

str_HELP_KEY	:= 	utils_name
strMode15:		.byte	"MODE15", 0
helpMode15:		.byte	"?", 0
strTTX80TEST:		.byte	"TTX80TEST", 0

