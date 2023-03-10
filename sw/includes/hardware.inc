	.IFNDEF __HARDWARE_INC__
__HARDWARE_INC__:




sheila_ACIA_CTL		:=	$FE08
ACIA_RDRF		:=	$01
ACIA_TDRE		:=	$02

sheila_ACIA_DATA	:=	$FE09
sheila_SERIAL_ULA	:=	$FE10



fred_JIM_PAGE_HI2		:=	$FCFC		; note ignored Blitter/Paula
fred_JIM_PAGE_HI		:=	$FCFD
fred_JIM_PAGE_LO		:=	$FCFE
fred_JIM_DEVNO			:=	$FCFF

jim_base			:=	$FD00
JIM				:=	jim_base

SHEILA_ROMCTL_SWR	:=	$FE30

	
SHEILA_NULA_CTLAUX	:=	$FE22
SHEILA_NULA_PALAUX	:=	$FE23


;***********************************************************************
;* System VIA                                                          *
;***********************************************************************
sheila_SYSVIA_orb			:= $FE40
sheila_SYSVIA_ora			:= $FE41
sheila_SYSVIA_ddrb			:= $FE42
sheila_SYSVIA_ddra			:= $FE43
sheila_SYSVIA_t1cl			:= $FE44
sheila_SYSVIA_t1ch			:= $FE45
sheila_SYSVIA_t1ll			:= $FE46
sheila_SYSVIA_t1lh			:= $FE47
sheila_SYSVIA_t2cl			:= $FE48
sheila_SYSVIA_t2ch			:= $FE49
sheila_SYSVIA_sr			:= $FE4A
sheila_SYSVIA_acr			:= $FE4B
sheila_SYSVIA_pcr			:= $FE4C
sheila_SYSVIA_ifr			:= $FE4D
sheila_SYSVIA_ier			:= $FE4E
sheila_SYSVIA_ora_nh			:= $FE4F


;***********************************************************************
;* User VIA                                                            *
;***********************************************************************
sheila_USRVIA_orb			:= $FE60
sheila_USRVIA_ora			:= $FE61
sheila_USRVIA_ddrb			:= $FE62
sheila_USRVIA_ddra			:= $FE63
sheila_USRVIA_t1cl			:= $FE64
sheila_USRVIA_t1ch			:= $FE65
sheila_USRVIA_t1ll			:= $FE66
sheila_USRVIA_t1lh			:= $FE67
sheila_USRVIA_t2cl			:= $FE68
sheila_USRVIA_t2ch			:= $FE69
sheila_USRVIA_sr			:= $FE6A
sheila_USRVIA_acr			:= $FE6B
sheila_USRVIA_pcr			:= $FE6C
sheila_USRVIA_ifr			:= $FE6D
sheila_USRVIA_ier			:= $FE6E
sheila_USRVIA_ora_nh			:= $FE6F

;***********************************************************************
;*  VIA constants                                                      *
;***********************************************************************

VIA_IFR_BIT_ANY				:= $80
VIA_IFR_BIT_T1				:= $40
VIA_IFR_BIT_T2				:= $20
VIA_IFR_BIT_CB1				:= $10
VIA_IFR_BIT_CB2				:= $08
VIA_IFR_BIT_SR				:= $04
VIA_IFR_BIT_CA1				:= $02
VIA_IFR_BIT_CA2				:= $01

VIA_ACR_SHIFTMODE_0			:= $00
VIA_ACR_SHIFTMODE_1			:= $04
VIA_ACR_SHIFTMODE_2			:= $08
VIA_ACR_SHIFTMODE_3			:= $0C
VIA_ACR_SHIFTMODE_4			:= $10
VIA_ACR_SHIFTMODE_5			:= $14
VIA_ACR_SHIFTMODE_6			:= $18
VIA_ACR_SHIFTMODE_7			:= $1C

VIA_ACR_T1_MASK				:= $C0
VIA_ACR_T1_CONT				:= $40


;***********************************************************************
;* BBC B/B+ WD177x                                                     *
;***********************************************************************

sheila_1770_dcontrol			:=	$FE80
sheila_1770_wdc_cmd			:=	$FE84
sheila_1770_wdc_trk			:=	$FE85
sheila_1770_wdc_sec			:=	$FE86
sheila_1770_wdc_dat			:=	$FE87

W1770_DRVSEL_BIT_SEL0			:= $01
W1770_DRVSEL_BIT_SEL1			:= $02
W1770_DRVSEL_BIT_SIDE1			:= $04
W1770_DRVSEL_BIT_nDDEN			:= $08
W1770_DRVSEL_BIT_nMR			:= $20


;***********************************************************************
;* CRTC                                                                *
;***********************************************************************
sheila_CRTC_reg				:= $FE00
sheila_CRTC_rw				:= $FE01


;***********************************************************************
;* Simple Video ULA                                                    *
;***********************************************************************
sheila_VIDULA_ctl			:= $FE20
sheila_VIDULA_pal			:= $FE21


;***********************************************************************
;* NEW API JIM DEVICE NOs                                              *
;***********************************************************************




JIM_DEVNO_HOG1MPAULA			:= $D0
JIM_DEVNO_BLITTER			:= $D1

	.ENDIF