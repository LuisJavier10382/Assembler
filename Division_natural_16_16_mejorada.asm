;;DIVISION ENTERA DE NÚMEROS NATURALES 16bits/16bits
;;
;;Emplea la instruccion "subwfb", que se encuentra en 
;;los Mid-Range 8 bits PICs (49 instrucciones o mas)
;;
;;Realiza la divisisn de dos numeros de 16bits
;;en aprox. 320 ciclos de instruccisn
;;usando desplazamientos en lugar de restas sucesivas
;;
;;Necesita 2 variables de 8 bits:TEMPORAL y W_L
;;Para que funcione, las variables de 16bits han de estar
;;en el orden HIGH:LOW (como se puede ver en las equ)
;;es decir, en la posicisn mas baja de la RAM el byte bajo
;;y en la siguiente posicion mas alta el byte alto
;;
;;Entrada: DIVIDENDO (16b) y DIVISOR(16b)
;;Salida: COCIENTE(16b) y RESTO(16b)
;;Borra DIVIDENDO, no altera DIVISOR


;*********************************************************************
;		Palabra de configuracisn de parametros del PIC 16F883
;*********************************************************************

	list		p=16f883		; directiva list para definir el tipo de Micro-Controlador
	#include	<p16f883.inc>		; definición de variables specificas del Micro-Controlador

	__CONFIG    _CONFIG1, _LVP_OFF & _FCMEN_ON & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG    _CONFIG2, _WRT_OFF & _BOR21V

;*********************************************************************
#ifndef 	Carry
#define		Carry	STATUS,C
#endif

#ifndef		lsl16
lsl16		MACRO	File
		lslf		File,F
		rlf		(File+.1),F
		endM
#endif

;;********************************************************************
;;**suprimir los punto y coma para su funcionamiento stand-alone**
;*********************************************************************

Temporal	equ		.127
CocienteH	equ		.126
Cociente	equ		.125
RestoH		equ		.124
Resto		equ		.123
DividendoH	equ		.122
Dividendo	equ		.121
DivisorH	equ		.120
Divisor		equ		.119
W_L		equ		.118

;*****************************************************************
;DIVIDENDO	equ	.6000	;Constantes usadas como ejemplo
;DIVISOR	equ	.14	;
;*****************************************************************

;	movlw		HIGH DIVIDENDO
;	movwf		DividendoH
;	movlw		LOW DIVIDENDO
;	movwf		Dividendo
;	movlw		HIGH DIVISOR
;	movwf		DivisorH
;	movlw		LOW DIVISOR
;	movwf		Divisor

;*****************************************************************

DIVIDE:
	clrf		Temporal
	clrf		CocienteH
	clrf		Cociente
	clrf		RestoH
	clrf		Resto
st:
	btfsc		Temporal,4
	return
	incf		Temporal
	lsl16		Cociente
	lsl16		Dividendo
	rlf		Resto
	rlf		(Resto+.1)
	movf		Divisor,W
	subwf		Resto,W
	movwf		W_L
	movf		DivisorH,W
	subwfb		RestoH,W
	btfss		Carry
	goto		st
	bsf		Cociente,0
	movwf		RestoH
	movf		W_L,W
	movwf		Resto
	goto		st

	end
