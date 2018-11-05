;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	                    	I2C SLAVE                         	   *
;*								  							       *
;*	       		DESENVOLVIDO POR LUCAS FERREIRA LIMA		   	   *
;*			 		     DATA: 09/10/18			  				   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   				MODELO PARA O PIC 16F628A                      *
;*  - O protocolo I2C deve ser implementado no PIC no modo SLAVE;  *
;*  - O PIC deve receber um byte de endereço e sinalizar sua       *
;*    identificação através de um LED;				      		   *
;*  - Quando o endereço for identificado como correto, um ACK deve *
;*    ser enviado e o sinal CLK deve forçado a LOW por 200 ms;     *
;*  - Um LED deve indicar que o endereço correto foi recebido,     *
;*    mantendo-o aceso pelo mesmo tempo do ACK em LOW;		   	   *
;*  - Para padronizar a utilização das portas, deve ser adotado:   *
;*	- RB7 - SCL						   							   *
;*	- RB6 - SDA						   							   *
;*	- RB5 - Led						   							   *
;*  - Endereço do Slave - 0x21					   				   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINIÇÕES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <p16f628a.inc>	;ARQUIVO PADRÃO MICROCHIP PARA 12F628A

	__CONFIG _BODEN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _MCLRE_ON & _INTRC_OSC_NOCLKOUT & _LVP_OFF

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    PAGINAÇÃO DE MEMÓRIA                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;DEFINIÇÃO DE COMANDOS DE USUÁRIO PARA ALTERAÇÃO DA PÁGINA DE MEMÓRIA
#DEFINE	BANK0	BCF STATUS,RP0	;SETA BANK 0 DE MEMÓRIA
#DEFINE	BANK1	BSF STATUS,RP0	;SETA BANK 1 DE MAMÓRIA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARIÁVEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DOS NOMES E ENDEREÇOS DE TODAS AS VARIÁVEIS UTILIZADAS 
; PELO SISTEMA

	CBLOCK	0x20	;ENDEREÇO INICIAL DA MEMÓRIA DE
					;USUÁRIO
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES

		RCONT	;VARIAVEL DE CONTAGEM 
		ADDR	;VARIAVEL PARA DATA RECEBIDO
	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA
	
#DEFINE ENDERECO H'21'	;ENDEREÇO DO SLAVE
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)
	
#DEFINE SCL PORTB,RB7	;PORTA DO SCL
#DEFINE SCL_IO TRISB,TRISB7 ;BIT DE CONTROLE I/O DO SCL
#DEFINE SDA PORTB,RB6	;PORTA DO SDA
#DEFINE SDA_IO TRISB,TRISB6	;BIT DE CONTROLE I/O DO SDA
#DEFINE LED PORTB,RB5	;PORTA DO LED

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SAÍDAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO SAÍDA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x00			;ENDEREÇO INICIAL DE PROCESSAMENTO
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    INÍCIO DA INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDEREÇO DE DESVIO DAS INTERRUPÇÕES. A PRIMEIRA TAREFA É SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERAÇÃO FUTURA

	ORG	0x04			;ENDEREÇO INICIAL DA INTERRUPÇÃO
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SERÁ ESCRITA AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUPÇÕES

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SAÍDA DA INTERRUPÇÃO                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUPÇÃO

SAI_INT
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	RETFIE

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.

;ROTINA QUE IRÁ RECEBER BYTE DO MASTER
;  7      6      5      4      3      2      1      0 
; ADR6 | ADR5 | ADR4 | ADR3 | ADR2 | ADR1 | ADR0 | W/R
RECIVE_BYTE
	CLRF	ADDR
	MOVLW	.8	
	MOVWF	RCONT
R_LOOP
	BTFSC	SCL	    ;ESPERA BORDA DE SUBIDA DO SCL
	GOTO	$-1
	BTFSS	SCL
	GOTO	$-1
	BCF	STATUS,C    ;LIMPA CARRY
	BTFSC	SDA	    ;SE SDA ESTIVER ATIVO
	BSF	STATUS,C    ;SETA CARRY
	RLF	ADDR	    ;ROTACIONA CARRY PARA REGISTRADOR ADDR
	DECFSZ	RCONT	    ;REPERE POR 8 VEZES
	GOTO	R_LOOP
	
	RETURN

;MANDA ACKNOWLEDGE BIT PARA MASTER
ACK
	BTFSC	SCL	    ;ESPERA CLOCK ESTAR EM LOW  
	GOTO	$-1
	BANK1
	BCF	SDA_IO	    ;MUDA PORTA DO SDA PARA SAÍDA
	BANK0
	BCF	SDA	    ;MANDA ACK, I.E SDA EM LOW
	
	BTFSC	SCL	    
	GOTO	$-1
	BTFSS	SCL	    ;ESPERA CLOCK IR PARA 1, I.E MASTER IRÁ LER ACK BIT
	GOTO	$-1
	
	BTFSC	SCL	    ;ESPERA CLOCK IR PARA ZERO
	GOTO	$-1
	
	BCF	SCL
	BANK1		
	BCF	SCL_IO	    ;MUDA PORTA DO SCL PARA SAÍDA
	BSF	SDA_IO	    ;LIBERA SDA
	BANK0
	BCF	SCL	    ;JOGA CLOCK PARA LOW, MASTER ESPERAR

	
	RETURN

;MANDA ACKNOLEDGE BIT, ACENDE LED, ESPERA 200MS, LIBERA CANAIS DO I2C
LIGHTUP_LED
	CALL	ACK	    ;MANDA ACKNOWLEDGE
	
	BSF	LED	    ;ACENDE LED
	CALL	DELAY_200MS ;ESPERA 200MS
	BCF	LED	    ;APAGA LED
	
	BANK1
	BSF	SCL_IO	    ;LIBERA SCL COLOCANDO A PORTA COMO ENTRADA
	BANK0
	
	RETURN

DELAY_200MS
	BCF	PIR1, TMR1IF
	MOVLW	H'3C'
	MOVWF	TMR1H
	MOVLW	H'B0'
	MOVWF	TMR1L
	
	BTFSS	PIR1, TMR1IF
	GOTO	$-1
	
	RETURN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1		;ALTERA PARA O BANCO 1
	MOVLW	B'00000000'	
	MOVWF	TRISA		
	MOVLW	B'11000000'	;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISB		;COMO SAÍDAS, RB6 E RB7 COMO ENTRADA
	MOVLW	B'00000000'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
	BANK0			;RETORNA PARA O BANCO 0
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO
	MOVLW	B'00100001'	;TMR1 PRESCALE 1:4
	MOVWF	T1CON
	MOVLW	B'00000000'
	MOVWF	T2CON
	CLRF	PORTA
	CLRF	PORTB
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
START_BIT
	BTFSS	SDA
	GOTO	START_BIT	;ESPERA START BIT
	BTFSC	SDA
	GOTO	$-1
	BTFSS	SCL
	GOTO	START_BIT
	    ;START BIT ACHADO
	CALL	RECIVE_BYTE	;RECEBE BYTE MANDADO PELO MASTER
	BCF	STATUS,C	
	RRF	ADDR
	MOVLW	ENDERECO	;TESTA SE ENDEREÇO RECEBIDO É O DESIGNADO
	SUBWF	ADDR, W
	BTFSC	STATUS, Z
	CALL	LIGHTUP_LED	;SE SIM, MANDA ACK E ACENDE LED
	GOTO	START_BIT   

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
	