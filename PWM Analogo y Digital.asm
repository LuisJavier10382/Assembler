

;*********************************************************************************

;	PWM generado con resultado del ADC
;	
;	

;*********************************************************************************

     LIST      p=16F88              ; list directive to define processor
    #INCLUDE <P16F88.INC>          ; processor specific variable definitions

   __CONFIG    _CONFIG1, _CP_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _PWRTE_ON & _WDT_OFF & _LVP_OFF

;*********************************************************************************

Contador1		EQU		0x20 			;
Contador2 		EQU 		0x21	 		;

TEMPOR_L		EQU		0X22
TEMPOR_H		EQU		0X23

CONTT			EQU		0X24

ZERO_H			EQU		0X25
ZERO_L			EQU		0X26

decre			EQU 	3 				; Pulsador para Aumentar Ciclo de Trabajo
incre				EQU 	4 				; Pulsador para Decrementar Ciclo de Trabajo

;*********************************************************************************
; 						VECTOR RESET
;*********************************************************************************

	RESET     	ORG     	0x0000     	; processor reset vector
          	PAGESEL 	START
          	GOTO    	START      	

		  	ORG     	0x0004     	; interrupt vector location

;*********************************************************************************
; 							PROGRAMA PRINCIPAL
;*********************************************************************************

START
			GOTO 	Inicio 			; Salto a inicio de mi programa.

CONFIG_PIC	BSF 		STATUS,RP0 		; Banco 1

			MOVLW	B'00011100'	; RA2 como entrada 
			MOVWF	ANSEL		; Analoga
			MOVWF	TRISA		
			CLRF		TRISB

			MOVLW	B'00000000'		
			MOVWF	ADCON1		; CONFIGURADO PARA ALINEACION A LA IZQUIERDA

			CLRF		OSCTUNE
			MOVLW	B'01100111'	
			MOVWF	OSCCON

			MOVLW	B'01000000'	; Configuramos el registro de interrupciones
			MOVWF	OPTION_REG

			BCF 		STATUS,RP0 	; Banco 0.

			MOVLW 	b'01110100' 	; Se selecciona TMR2, preescaler de 1/16.
			MOVWF 	T2CON
			BSF 		STATUS,RP0 	; Banco 1

			
			MOVLW 	0xFF 			; Seqal de 2kHz
			MOVWF 	PR2
			BCF 		STATUS,RP0 	; Banco 0

			CLRF 	CCPR1L 			; Ciclo de trabajo 0%
			CLRF 	CCPR1H 

			BSF		CCP1CON,5
			BCF		CCP1CON,4

			BCF 		CCP1CON,CCP1X
			BCF 		CCP1CON,CCP1Y
			BSF 		CCP1CON,CCP1M3 	; Configura modulo CCP modo PWM.
			BSF 		CCP1CON,CCP1M2

			RETURN

;*********************************************************************************
;							PROG ANALOGO DIGITAL
;*********************************************************************************

ANALOG		NOP					; SIN INSTRUCCION, GENERA UN RETARDO
			MOVLW	B'11010001'
			MOVWF	ADCON0		; CONFIGURO EL ADCON0, EL BIT 0 DEBE ESTAR EN 1 PARA OPERAR COMO CONVERSOR ANALOGO DIGITAL
			NOP
			NOP
			CALL		MUESTREO
			BSF		ADCON0,2
			NOP

FIN			BTFSC	ADCON0,2	; EVALUA SI TERMINA LA CONVERSION
			GOTO	FIN

			BANKSEL	ADRESH
			MOVF	ADRESH,W
			BANKSEL	TEMPOR_H
			MOVWF	TEMPOR_H
			RETURN

;*********************************************************************************
;					TIEMPO DE RECOLECCION DE DATOS
;*********************************************************************************

MUESTREO	MOVLW	.25
			MOVWF	CONTT
REC			DECFSZ	CONTT
			GOTO	REC

			RETURN

;*********************************************************************************
;      RUTINA QUE REALIZA INVERSION DE GIRO DEL MOTOR Y CONTROLA EL PWM DESDE ADC
;*********************************************************************************

PWM_ADC	MOVFW	TEMPOR_H

			BTFSS	ADRESH,7
			GOTO	DER

IZQ			BCF		PORTB,2
			BSF		PORTB,1
			RLF		TEMPOR_H
			GOTO	CARGAR

DER			BCF		PORTB,1
			BSF		PORTB,2
			RLF		TEMPOR_H
			COMF	TEMPOR_H
		
CARGAR		MOVF	TEMPOR_H,W
			MOVWF	CCPR1L

			RETURN
;*********************************************************************************
;	RUTINA PARA INCREMENTAR Y DECREMENTAR PWM DESDE PULSADORES EN RA0 Y RA1
;*********************************************************************************

PWM_DIG		BTFSC	PORTA,0 			; PORTA,3 	; Testea si se quiere reducir CT.
			GOTO 	Decrementa
			BTFSC	PORTA,1			; PORTA,4 	; Testea si se quiere aumentar CT.
			GOTO 	Incrementa
			RETURN					;GOTO 	Bucle

Incrementa
			INCF 	CCPR1L,1
			CALL 	Demora_50ms
			RETURN					;GOTO 	Bucle

Decrementa
			DECF 	CCPR1L,1
			CALL 	Demora_50ms
			RETURN

;*********************************************************************************
;						RUTINA DE RETARDO
;*********************************************************************************

Demora_50ms
			MOVLW 	0xFF ;
			MOVWF 	Contador1 		; Iniciamos contador1.

Repeticion1	
			MOVLW 	0x40 ;
			MOVWF 	Contador2 		; Iniciamos contador2

Repeticion2
			DECFSZ 	Contador2,1 	; Decrementa Contador2 y si es 0 sale.
			GOTO 	Repeticion2 	; Si no es 0 repetimos ciclo.
			DECFSZ 	Contador1,1 	; Decrementa Contador1.
			GOTO 	Repeticion1 	; Si no es cero repetimos ciclo.}

			RETURN 				; Regresa de la subrutina.

;*********************************************************************************
;							PROGRAMA PRINCIPAL
;*********************************************************************************

Inicio
			CALL		CONFIG_PIC
			CLRF		PORTB

LOOP
			CALL		ANALOG
			CALL		PWM_ADC
;			CALL		PWM_DIG		
			GOTO	LOOP

	   		END
