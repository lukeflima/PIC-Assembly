;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         PISCA ALERTA	                           *
;*								  							       *
;*	       		DESENVOLVIDO POR LUCAS FERREIRA LIMA		   	   *
;*			 		     DATA: 20/08/18			  				   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   MODELO PARA O PIC 12F675                                      *
;* • Um interruptor de 3 posições, para acender 2 LEDs 			   *
;* 	 (LED-E e LED-D);											   *
;*   • Quando na posição central, o LED-E e o LED-D permanecem 	   *
;*     apagados;												   *
;*   • Quando na posição E (esquerda), o LED-E piscará com 		   *
;*     frequência de 1 Hz;										   *
;*   • Quando na posição D (direita), o LED-D piscará com 		   *
;*     frequência de 1 Hz;										   *
;* • Um interruptor (liga-desliga), para piscar os dois LEDs ao	   *
;*   mesmo tempo (função alerta), com frequência de 1 Hz. 		   *
;*   Esse interruptor deve ter maior prioridade;				   *
;* • GP0 deverá ser utilizado com o interruptor que comandará 	   *
;*   a função "alerta";											   *
;* • GP1 e GP2 deverão ser utilizados para o interruptor de 	   *
;*   3 posições; 												   *
;* • GP4 e GP5 deverão ser utilizados, respectivamente, para os    *
;*   LED-E e LED-D.                                        		   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINIÇÕES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <p12f675.inc>	;ARQUIVO PADRÃO MICROCHIP PARA 12F675

	__CONFIG _BODEN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _MCLRE_ON & _INTRC_OSC_NOCLKOUT

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

		;NOVAS VARIÁVEIS
		MODE

	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA
#DEFINE	MODE_E	MODE,0
#DEFINE	MODE_D	MODE,1
#DEFINE	MODE_A	MODE,2
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

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
	BTFSS	INTCON,	GPIF	;CHECA SE INTERRUPÇÃO É DE PORT CHANGE
	GOTO	TIMERINT	;SE NÃO, VAI PARA CHECAGEM DE INT TIMER
	BCF	INTCON, GPIF	;SE SIM, LIMPA FLAG	
	
	BTFSS	GPIO, GP0	;TESTA SE SWTICH ALERTA ESTA ATIVO
	GOTO	ESQUERDA	;SE NÃO, TESTAR SE SWTICH TA NA ESQUERDA
	BTFSC	MODE_A		;TESTA SE MODO ALERTA JÁ ESTÁ ATIVO
	GOTO	SAI_INT		;SE SIM, SALTA PARA O FIM DO TRAT DE INT
	BSF	GPIO, GP4	;SE NÃO, ACENDE OS LEDS 'E' E 'D',
	BSF	GPIO, GP5	;CONFIGURA O TIMER E SETA MODO ALERTA PARA ATIVO
	BSF	MODE_A
	BCF	MODE_E		
	BCF	MODE_D
	CALL	TIMERINIT
	GOTO	SAI_INT
ESQUERDA
	BCF	MODE_A		;LIMPA MODO ALERTA
	BTFSS	GPIO, GP1	;TESTA SE SWITCH ESTÁ NA ESQUERDA
	GOTO	DIREITA		;SE NÃO, TESTAR SE SWITCH TA NA DIREIRA
	BTFSC	MODE_E		;TESTA SE MODO ESQUERDA JÁ ESTÁ ATIVO
	GOTO	SAI_INT		;SE SIM, SALTA PARA O FIM DO TRAT DE INT
	BSF	GPIO, GP4	;ACENDE LED-E
	BCF	GPIO, GP5	;APAGA	LED-D
	BSF	MODE_E		;SETA MODO ESQUERDA COMO ATIVO
	BCF	MODE_D
	BCF	MODE_A
	CALL	TIMERINIT	;CONFIGURA TIMER
	GOTO	SAI_INT
DIREITA
	BCF	MODE_E
	BTFSS	GPIO, GP2	;TESTA SE SWITCH ESTÁ NA DIREITA
	GOTO	DFIM		;SE NÃO, DESATIVAR MODO DIREITA
	BTFSC	MODE_D		;TESTA SE MODO DIREITA JÁ ESTÁ ATIVO
	GOTO	SAI_INT		;SE SIM, SALTA PARA O FIM DO TRAT DE INT
	BCF	GPIO, GP4	;APAGA LED-E
	BSF	GPIO, GP5	;ACENDE LED-D
	BSF	MODE_D		;SETA MODO DIREITA COMO ATIVO
	BCF	MODE_E
	BCF	MODE_A		
	CALL	TIMERINIT	;CONFIGURA TIMER
	GOTO	SAI_INT

TIMERINT
	BTFSS	PIR1, TMR1IF	;CHECA SE INTERRUPÇÃO É DO TIMER1
	GOTO	SAI_INT
	BCF	PIR1, TMR1IF	;LIMPA FLAG DE INT DO TMR1
	BTFSS	MODE_A		;TESTA SE MODO ALERTA ESTA ATIVO
	GOTO	$+2		;SE NÃO, TESTA MODO ESQUERDA
	GOTO	ALERTAMUDA	;SE SIM, MUDAR ESTADO DOS LEDS
	BTFSS	MODE_E		;TESTA SE MODO ESQUERDA ESTA ATIVO
	GOTO	$+2		;SE NÃO, TESTAR MODO DIREITA
	GOTO	ESQUERDAMUDA	;SE SIM, MUDAR ESTADO DO LED-E
	BTFSS	MODE_D		;TESTA SE MODO DIREITA ESTA ATIVO
	GOTO	SAI_INT		;SE NÃO, SAIR DA INTERRUPÇÃO
	GOTO	DIREITAMUDA	;SE SIM, MUDAR ESTADO DO LED-D
ALERTAMUDA
	COMF	GPIO		;INVERTE ESTADO DOS LEDS
	CALL	TIMERINIT
	GOTO	SAI_INT
ESQUERDAMUDA
	BTFSS	GPIO, GP4	;CHECA SE LED-E ESTA ACESO
	GOTO	ACENDE_E	;SE NÃO, ACENDE
	GOTO	APAGA_E		;SE SIM, APAGA
ACENDE_E
	BSF	GPIO,GP4	;ACENDE LED-E
	CALL	TIMERINIT	;CONFIGURA TIMER
	GOTO	SAI_INT
APAGA_E
	BCF	GPIO,GP4	;APAGA LED-E
	CALL	TIMERINIT	;CONFIGURA TIMER
	GOTO	SAI_INT	
DIREITAMUDA
	BTFSS	GPIO, GP5	;CHECA SE LED-D ESTA ACESO
	GOTO	ACENDE_D	;SE NÃO, ACENDE
	GOTO	APAGA_D		;SE SIM, APAGA
ACENDE_D
	BSF	GPIO,GP5	;ACENDE LED-D
	CALL	TIMERINIT	;CONFIGURA TIMER
	GOTO	SAI_INT
APAGA_D
	BCF	GPIO,GP5	;APAGA LED-D
	CALL	TIMERINIT	;CONFIGURA TIMER
	GOTO	SAI_INT	
DFIM
	BCF	MODE_D	    ;DESATIVA MODO DIREITA
	BCF	MODE_E	    ;DESATIVA MODO ESQUERTA
	BCF	MODE_A	    ;DESATIVA MODO ALERTA
	BCF	T1CON, TMR1ON	;DESLIGA TIMER1
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
;*	            	 ROTINAS E SUBROTINAS                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.

;CONFIGURA TIMER1 PARA 500MS PS 1:8
TIMERINIT
	MOVLW	0XDC	;COLOCA 0XBDC NO TIMER1
	MOVWF	TMR1L
	MOVLW	0X0B
	MOVWF	TMR1H
	BSF	T1CON, TMR1ON	;LIGA TIMER1

	RETURN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	B'00000111' ;CONFIGURA GP0, GP1, GP2 COMO ENTRADA
	MOVWF	TRISIO		;E GP4 E GP5 COMO SAIDA
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O
	MOVLW	B'00000100'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'11001000'	;HABILITA INT, INT PERIFERICO E INT PORT CHANGE
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
	BSF	PIR1, TMR1IF	;HABILITAR INTERRUPÇÃO TMR1
	MOVLW	B'00000111'
	MOVWF	IOC
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00110000'	;TMR1 PRESCALE 1:8
	MOVWF	T1CON
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	;SETUP INCIAL
	BTFSS	GPIO, GP0   ;CHEGA SE ALERTA ESTA ATIVO
	GOTO	$+2	    ;SE NÃO, CHECAGEM DOS DEMAIS MODOS
	GOTO	SETUP1	    ;SE SIM, CONFIGURA LEDS 'D' E 'E' E TIMER
	
	BTFSS	GPIO, GP1   ;CHEGA SE SWITCH ESTA NA ESQUERDA
	GOTO	$+2	    ;SE NAO, CHECAGEM SE ESTÁ NA DIREITA
	GOTO	SETUP2	    ;SE SIM, CONFIGURA LED 'E' E 
	
	BTFSS	GPIO, GP2   ;CHECA SE SWITCH ESTA NA DIRETA
	GOTO	MAIN	    ;SE NÃO, LOOP INFINITO
	GOTO	SETUP3	    ;SE SIM, CONFIGURA LED 'D' E TIMER
SETUP1
	BSF	GPIO, GP4   ;ACENDE LED-E  E LED-D
	BSF	GPIO, GP5 
	BSF	MODE_A
	GOTO	TIMER	    ;CONFIGURA TIMER
SETUP2
	BSF	GPIO, GP4   ;ACENDE LED-E
	BSF	MODE_E
	GOTO	TIMER	    ;CONFIGURA TIMER
SETUP3
	BSF	MODE_D
	BSF	GPIO, GP5   ;ACENDO LED-D
TIMER
	CALL	TIMERINIT

MAIN

	;CORPO DA ROTINA PRINCIPAL
	
	GOTO MAIN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
