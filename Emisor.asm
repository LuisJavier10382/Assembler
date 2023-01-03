;**********************************************************************
;   This file is a basic code template for assembly code generation   		*
;   on the PIC16F84A. This file contains the basic code               			*
;   building blocks to build upon.                                    					*  
;                                                                     							*
;   Refer to the MPASM User's Guide for additional information on     		*
;   features of the assembler (Document DS33014).                     			*
;                                                                     							*
;   Refer to the respective PIC data sheet for additional             			*
;   information on the instruction set.                               				*
;                                                                     							*
;**********************************************************************
; 	                                                               							*
;    Filename:		Display Remoto.asm                         				*
;    Date:			Noviembre 13 / 2022						*
;    File Version:		2.0									*
;                                                                     							*
;    Author:               	Ing. Luis Javier Romero Anaya                                        	*
;    Company:                   Basculas y Balanzas						*
;                                                                     							* 
;                                                                     							*
;**********************************************************************
;                                                                     							*
;    Files Required: P16F887.INC                                      					*
;                                                                     							*
;**********************************************************************
;                                                                     							*
;    Notes:                                                           						*              
;                                                                     							*
;**********************************************************************


;*********************************************************************************************************************************************************************

	list		p=16f883	; list directive to define processor
	#include	<p16f883.inc>	; processor specific variable definitions

	__CONFIG    _CONFIG1, _LVP_OFF & _FCMEN_ON & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG    _CONFIG2, _WRT_OFF & _BOR21V

;*********************************************************************************************************************************************************************

;***** VARIABLE DEFINITIONS
w_temp		EQU	0x7D		; variable used for context saving
status_temp	EQU	0x7E		; variable used for context saving
pclath_temp	EQU	0x7F		; variable used for context saving

;***** VARIABLE DEFINITIONS

DATO1		EQU		0X21
DATO2		EQU		0X22
DATO3		EQU		0X23
TIEMPO1		EQU		0X24
TIEMPO2		EQU		0X25
TIEMPO3		EQU		0X26

;***********************************************************************
;	Registros para guardar resultado de multiplicacion de 32 bit's
;		<Resultado_d, Resultado_c, Resultado_b, Resultado_a>
;***********************************************************************
Resultado_a	EQU	0X27
Resultado_b	EQU	0X28
Resultado_c	EQU	0X29
Resultado_d	EQU	0X2A

;***********************************************************************
;	REGISTROS PARA CONVERSION BIN_32bit's - BCD
;***********************************************************************
;	Registros para guardar resultado de la conversion 32 bit's
;		<BCD_val_3, BCD_val_2, BCD_val_1, BCD_val_0>
;***********************************************************************
BCD_val_0		EQU 	0X2B
BCD_val_1		EQU	0X2C
BCD_val_2		EQU	0X2D
BCD_val_3		EQU	0X2E
;***********************************************************************
;	Registros donde se almacena el valor de 32 bit's
;		<Byte_3, Byte_2, Byte_1, Byte_0>
;***********************************************************************
Byte_0		EQU	0X2F
Byte_1		EQU	0X30
Byte_2		EQU	0X31
Byte_3		EQU	0X32
;***********************************************************************
;		registro temporario de Bin32bit's - BCD
;***********************************************************************
MCount		EQU	0X33
Temp		EQU	0X34
;***********************************************************************

UNI			EQU	0X35
DEC			EQU	0X36
CENT			EQU	0X37
MIL			EQU	0X38
DIEZ_MIL		EQU	0X39
CIEN_MIL		EQU	0X3A
MILLON		EQU	0X3B
DIEZ_MILLON	EQU	0X3C
MIL_MILLON	EQU	0X3D
CIEN_MILLON	EQU	0X3E

CONTT		EQU		0X40
AUX			EQU		0X41
MOSTRAR1	EQU		0X42
MOSTRAR2	EQU		0X43
TEMPORAL	EQU		0X44

;**************************************************************************
		ORG     0x000           	  	; processor reset vector
		nop
  		goto    MAIN            		; go to beginning of program

		ORG     0x004            		; interrupt vector location	
;**************************************************************************
; 				MANEJO DE INTERRUPCIONES
;**************************************************************************
Inicio_ISR
		movwf	w_temp            	; save off current W register contents
		movf		STATUS,w          	; move status register into W register
		movwf	status_temp	; save off contents of STATUS register
		movf		PCLATH,w	  	; move pclath register into w register
		movwf	pclath_temp	; save off contents of PCLATH register
ISR
		CLRF		PORTC
		BTFSS 	INTCON,RBIF 	; Consultamos si es por cambio de estado en RB7
		GOTO	Rx
		GOTO	EXTERNA

		BTFSS 	PIR1,RCIF		; No, entonces preguntamos si es por Rx
		GOTO	Fin_Inter

Rx
		CALL		ENVIAR
		;INCFSZ	Resultado_a
		clrf		Resultado_a

		MOVLW	0DH			; PARA DEJARLO EN LA MISMA LINEA
		MOVWF	AUX
		CALL 	TRANSM

		BCF		PIR1,RCIF
		MOVF	RCREG,W
		MOVWF	PORTA
		MOVWF	AUX
		CALL 	TRANSM

		INCF		AUX
		CALL 	TRANSM

		MOVLW	0DH			; PARA DEJARLO EN LA MISMA LINEA
		MOVWF	AUX
		CALL 	TRANSM

		MOVLW	0DH			; PARA DEJARLO EN LA MISMA LINEA
		MOVWF	AUX
		CALL 	TRANSM
		GOTO	Fin_Inter

EXTERNA	
		BCF		INTCON,RBIF
		BCF		INTCON,INTF
		CALL		ENVIAR
		CLRF		INTCON
		INCFSZ	Resultado_a
		GOTO	Fin_Inter

;Fin_ISR
Fin_Inter
		BCF		PIR1,RCIF
		BCF		INTCON,RBIF

		movf		pclath_temp,w	; retrieve copy of PCLATH register
		movwf	PCLATH		; restore pre-isr PCLATH register contents
		movf    	status_temp,w     	; retrieve copy of STATUS register
		movwf	STATUS            	; restore pre-isr STATUS register contents
		swapf   	w_temp,f
		swapf   	w_temp,w          	; restore pre-isr W register contents
		RETFIE          		 		; return from interrupt

;**************************************************************************
;					PROGRAMA PRINCIPAL
;**************************************************************************

MAIN	CLRF		TEMPORAL
		CALL		CONFIG_PIC

		CLRF		Resultado_a
		CLRF		Resultado_b
		CLRF		Resultado_c
		CLRF		Resultado_d

		CLRF		Byte_0
		CLRF		Byte_1
		CLRF		Byte_2
		CLRF		Byte_3

		CLRF		UNI
		CLRF		DEC
		CLRF		CENT			
		CLRF		MIL			
		CLRF		DIEZ_MIL		
		CLRF		CIEN_MIL		
		CLRF		MILLON		
		CLRF		DIEZ_MILLON	
		CLRF		CIEN_MILLON

LOOP	BTFSC	PORTA,2
		CALL 	ENVIAR
		NOP
		NOP
		CALL		HexBCD
		CALL		VISUAL
	;	CALL		MOSTRAR
		BTFSC	PORTA,1
		INCFSZ	Resultado_a
		GOTO	LOOP
		INCFSZ	Resultado_b
		GOTO	LOOP
		INCFSZ	Resultado_c
		GOTO	LOOP
		INCFSZ	Resultado_d

		GOTO	LOOP

;**************************************************************************
;					RUTINA DE CONFIGURACIÓN
;**************************************************************************

CONFIG_PIC	BSF		STATUS,5		; Banco 1	

			CLRF		TRISA		; CONFIGURO EL PORTA COMO ENTRADA
			BSF		TRISA,2

			MOVLW	B'10000000'	; PORTB,7 como entrada; Pull-Up habilitada
			MOVWF	TRISB
			MOVWF	WPUB
			MOVWF	IOCB

			MOVLW	B'10000000'
			MOVWF	TRISC		; PORTC como salida

			MOVLW	B'00000000'	; Habilito Pull-Up y Flanco de subida
			MOVWF	OPTION_REG
;********************************************************************************

			MOVLW	B'00100100'	; CONFIGURACION DE TX A 8 BITS, EN MODO ESCLAVO 
			MOVWF	TXSTA		; Y ASINCRONICO Y ALTA VELOCIDAD
			MOVLW	.25			; CARGA EL GENERADOR DE BAUDIOS CON 25 PARA LA 
			MOVWF	SPBRG		; TRANSMISION A ALTA VELOCIDAD DE 9600 BAUDIOS
			BSF		PIE1,RCIE		; Habilito interrupción por Rx
;********************************************************************************

			BCF		STATUS,5		; Banco 0
			MOVLW	B'10010000'	; ACTIVA EL BIT 7:SPEN PARA HABILITAR EL PUERTO SERIE
			MOVWF	RCSTA		; ACTIVA EL BIT 5:CREN PARA RECEPCIÓN

			;BANKSEL	INTCON
			;MOVLW	B'11000000'	; Habilito interrupciones globales, Periféricas 
			;MOVWF	INTCON		; y Por cambio de estado en entradas  Port_B
			BANKSEL	ANSEL
			CLRF		ANSEL

			BANKSEL	PORTA
			CLRF		PORTA
			CLRF		PORTB
			CLRF		PORTC

			RETURN

;********************************************************************************
;					RUTINA DE RETARDOS
;********************************************************************************

RETARDOTE	MOVLW		.255
			MOVWF		TIEMPO1
			GOTO		DEC1 	
RETARDO		MOVLW		.20
			MOVWF		TIEMPO1
DEC1			MOVLW		.2
			MOVWF		TIEMPO2
DEC2			MOVLW		.1
			MOVWF		TIEMPO3
DEC3			DECFSZ		TIEMPO3
			GOTO		DEC3
			DECFSZ		TIEMPO2
			GOTO		DEC2
			DECFSZ		TIEMPO1
			GOTO		DEC1
			RETURN

;**************************************************************************
;					RUTINA DE BCD - 7SEGMENTOS
;**************************************************************************
TABLA_7SEG 	
		ADDWF	PCL,F				;PARA DISPLAY DE CÁTODO COMÚN
		RETLW	B'11000000'	;0		B'00111111' ;	
		RETLW	B'11111001'	;1		B'00000110' ;			
		RETLW	B'10100100'	;2		B'01011011' ;			
		RETLW	B'10110000'	;3		B'01001111' ;			
		RETLW	B'10011001'	;4		B'01100110' ;			
		RETLW	B'10010010'	;5		B'01101101' ;			
		RETLW	B'10000011'	;6		B'01111100' ;		
		RETLW	B'11111000'	;7		B'00000111' ;	
		RETLW	B'10000000'	;8		B'01111111' ;	
		RETLW	B'10011000'	;9		B'01100111' ;	


;TABLA_7SEG 						;PARA DISPLAY DE CÁTODO COMÚN
		ADDWF	PCL,F	
		RETLW	B'00111111'	;0
		RETLW	B'00000110'	;1		 			
		RETLW	B'01011011'	;2				
		RETLW	B'01001111'	;3				
		RETLW	B'01100110' 	;4				
		RETLW	B'01101101'	;5				
		RETLW	B'01111100'	;6			
		RETLW	B'00000111'	;7		
		RETLW	B'01111111'	;8		
		RETLW	B'01100111'	;9		

;**************************************************************************
;	CONVERTIDOR BINARIO 32 BIT - BCD (DECIMAL)
;**************************************************************************

HexBCD
		MOVF	Resultado_a,W
		MOVWF	Byte_0
		MOVF	Resultado_b,W
		MOVWF	Byte_1
		MOVF	Resultado_c,W
		MOVWF	Byte_2
		MOVF	Resultado_d,W
		MOVWF	Byte_3
		
    		MOVLW 	d'32'			; Contador para el 
		MOVWF 	MCount		; corrimiento de los 32 BIT

		CLRF 	BCD_val_0
		CLRF 	BCD_val_1
		CLRF 	BCD_val_2
		CLRF 	BCD_val_3

		BCF 		STATUS,C
loop16 	
		RLF		Byte_0		; Resultado_a  de la Multiplicacion
		RLF 		Byte_1		; Resultado_b  de la Multiplicacion
		RLF 		Byte_2		; Resultado_c  de la Multiplicacion
		RLF 		Byte_3		; Resultado_d   de la Multiplicacion


		RLF 		BCD_val_0,F
		RLF 		BCD_val_1,F
		RLF 		BCD_val_2,F
		RLF 		BCD_val_3,F

		DECF 	MCount,F
		BTFSC 	STATUS,Z
		RETURN

adjDEC  	MOVLW 	BCD_val_0
		MOVWF 	FSR
		CALL 	adjBCD

		MOVLW 	BCD_val_1
		MOVWF 	FSR
		CALL 	adjBCD

		MOVLW 	BCD_val_2
		MOVWF 	FSR
		CALL 	adjBCD

		MOVLW 	BCD_val_3
		MOVWF 	FSR
		CALL 	adjBCD

		GOTO 	loop16

adjBCD	MOVLW 	d'3'
		ADDWF 	INDF,W
		MOVWF 	Temp
		BTFSC 	Temp,3
		MOVWF 	INDF
		MOVLW 	30h
		ADDWF 	INDF,W
		MOVWF 	Temp
		BTFSC 	Temp,7
		MOVWF 	INDF

		RETURN

;**************************************************************************
;					RUTINA DE VISUALIZACIÓN
;**************************************************************************
			
VISUAL
		MOVLW	B'00001111'
		ANDWF	BCD_val_3,W
		MOVWF	MILLON

		SWAPF	BCD_val_3
		MOVLW	B'00001111'
		ANDWF	BCD_val_3,W
		MOVWF	DIEZ_MILLON

		MOVLW	B'00001111'
		ANDWF	BCD_val_2,W	
		MOVWF	DIEZ_MIL

		SWAPF	BCD_val_2
		MOVLW	B'00001111'
		ANDWF	BCD_val_2,W
		MOVWF	CIEN_MIL

		MOVLW	B'00001111'
		ANDWF	BCD_val_1,W
		MOVWF	CENT

		SWAPF	BCD_val_1
		MOVLW	B'00001111'
		ANDWF	BCD_val_1,W
		MOVWF	MIL

		MOVLW	B'00001111'
		ANDWF	BCD_val_0,W
		MOVWF	UNI

		SWAPF	BCD_val_0
		MOVLW	B'00001111'
		ANDWF	BCD_val_0,W
		MOVWF	DEC

		MOVLW	.150			; CARGO LAS VECES QUE SE VISUALIZARA
		MOVWF	MOSTRAR1	; EN LOS DISPLAY EL VALOR DEL CONTADOR
							; ANTES DE INCREMENTAR O DECREMENTAR
		RETURN
;**************************************************************************

MOSTRAR

C_MIL	MOVF	CIEN_MIL,W
		CALL		TABLA_7SEG	; PRIMERO VISUALIZO LAS UNIDADES
		MOVWF	PORTB		; Habilito dígito 5

		MOVLW	.0
		SUBWF	CIEN_MIL,W
		BTFSC	STATUS,2
		GOTO	D_MIL

		BSF		PORTC,0
		CALL		RETARDO	
		CLRF		PORTC
;**************************************************************************

D_MIL	MOVF	DIEZ_MIL,W
		CALL		TABLA_7SEG	; VISUALIZO LAS DECENAS DE MIL
		MOVWF	PORTB		; Habilito dígito 4

		MOVLW	.0
		SUBWF	CIEN_MIL,W
		BTFSC	STATUS,2
		SUBWF	DIEZ_MIL,W
		BTFSC	STATUS,2
		GOTO	_MIL

		BSF		PORTC,1
		CALL		RETARDO
		CLRF		PORTC	
;**************************************************************************
		
_MIL		MOVF	MIL,W
		CALL		TABLA_7SEG	; VISUALIZO UNIDADES DE MIL
		MOVWF	PORTB		; Habilito dígito 3

		MOVLW	.0
		SUBWF	CIEN_MIL,W
		BTFSC	STATUS,2
		SUBWF	DIEZ_MIL,W
		BTFSC	STATUS,2
		SUBWF	MIL,W
		BTFSC	STATUS,2
		GOTO	CIEN

		BSF		PORTC,2
		CALL		RETARDO
		CLRF		PORTC
;**************************************************************************

CIEN		MOVF	CENT,W
		CALL		TABLA_7SEG	; VISUALIZO CENTENAS
		MOVWF	PORTB		; Habilito dígito 2

		MOVLW	.0
		SUBWF	CIEN_MIL,W
		BTFSC	STATUS,2
		SUBWF	DIEZ_MIL,W
		BTFSC	STATUS,2
		SUBWF	MIL,W
		BTFSC	STATUS,2
		SUBWF	CENT,W
		BTFSC	STATUS,2
		GOTO	DIEZ

		BSF		PORTC,3
		CALL		RETARDO
		CLRF		PORTC
;**************************************************************************

DIEZ		MOVF	DEC,W
		CALL		TABLA_7SEG	; VISUALIZO DECENAS
		MOVWF	PORTB		; Habilito dígito 1

		MOVLW	.0
		SUBWF	CIEN_MIL,W
		BTFSC	STATUS,2
		SUBWF	DIEZ_MIL,W
		BTFSC	STATUS,2
		SUBWF	MIL,W
		BTFSC	STATUS,2
		SUBWF	CENT,W
		BTFSC	STATUS,2
		SUBWF	DEC,W
		BTFSC	STATUS,2
		GOTO	UNID

		BSF		PORTC,4
		CALL		RETARDO	
		CLRF		PORTC
;**************************************************************************

UNID

		MOVF	UNI,W
		CALL		TABLA_7SEG	;VISUALIZO Unidades
		MOVWF	PORTB		; Habilito dígito 0

		BSF		PORTC,5
		CALL		RETARDO	
		CLRF		PORTC

		DECFSZ	MOSTRAR1	;SI TERMINÓ DE VISUALIZAR 
		GOTO	MOSTRAR		;RETORNE, SINÓ VUELVA A VISUALIZAR
		RETURN	

;**************************************************************************
;	RUTINA DE ENVÍO DE DATOS AL COMPUTADOR (9600, 8 BIT, 
;**************************************************************************

TRANSM    ; NOP
		;BANKSEL	TRISA		; Cambia al banco 1
		;BSF		TXSTA,5		; lleva a cero el bit 5 de TXSTA,
		;NOP
		;BANKSEL	PORTA	
 		CALL		RETARDOTE
		
		BCF		PIR1,TXIF		;;;;;;;;;;;;;
		MOVF	AUX,W
		MOVWF	TXREG
		BANKSEL     TRISA			

CONFIR4	BTFSS	TXSTA,TRMT	
		GOTO	CONFIR4
		BANKSEL   	PORTA
		RETURN

;**************************************************************************
;		CONVERSION ASCII Y TRANSMITE
;**************************************************************************

;ENVIAR	;MOVLW	0DH			;PARA DEJARLO EN LA MISMA LINEA
		;MOVWF	AUX
		;CALL		TRANSM

		MOVLW	3DH		; =
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	2DH		; S
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	30H		; 0
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	31H		; 1
		MOVWF	AUX
		CALL		TRANSM
		CALL		RETARDOTE

		MOVLW	32H		; 2
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	33H		; 3
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	34H		; 4
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	35H		; 5
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	36H		; 6
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	'.'
		MOVWF	AUX
		CALL		TRANSM

		MOVLW	37H		; 7
		MOVWF	AUX
		CALL		TRANSM

		CALL		RETARDOTE

		MOVLW	20H		;
		MOVWF	AUX
		CALL		TRANSM

	;RETURN

ENVIAR	MOVLW	3DH		; =
		MOVWF	AUX
		CALL		TRANSM

	;	MOVLW	2BH		; S
	;	MOVWF	AUX
	;	CALL		TRANSM
;
		MOVF	CIEN_MIL,W
		ADDLW	030H
		MOVWF	AUX
		CALL		TRANSM

		MOVF	DIEZ_MIL,W
		ADDLW	030H
		MOVWF	AUX
		CALL		TRANSM
	
		MOVF	MIL,W
		ADDLW	030H
		MOVWF	AUX
		CALL		TRANSM

		MOVF	CENT,W
		ADDLW	030H
		MOVWF	AUX
		CALL		TRANSM

		;MOVLW	','
		;MOVWF	AUX
		;CALL		TRANSM

		MOVF	DEC,W
		ADDLW	030H
		MOVWF	AUX
		CALL		TRANSM

		MOVF	UNI,W
		ADDLW	030H
		MOVWF	AUX
		CALL		TRANSM

		MOVLW	' '
		MOVWF	AUX
		CALL		TRANSM

		MOVLW	'K'
		MOVWF	AUX
		CALL		TRANSM

		MOVLW	'g'
		MOVWF	AUX
		CALL		TRANSM

		MOVLW	' '
		MOVWF	AUX
		CALL		TRANSM

		MOVLW	0DH			;PARA DEJARLO EN LA MISMA LINEA
		MOVWF	AUX
		CALL		TRANSM

		;MOVF	Resultado_a,W
		;ADDLW	030H
		;MOVWF	AUX
		;CALL		TRANSM

		RETURN

		END
