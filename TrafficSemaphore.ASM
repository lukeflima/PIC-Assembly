;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     SEMÁFORO DE TRÂNSITO                        *
;*								  							       *
;*	       		DESENVOLVIDO POR LUCAS FERREIRA LIMA		   	   *
;*			 		     DATA: 25/07/18			  				   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   MODELO PARA O PIC 12F675                                      *
;* Especificações:												   *
;* • Utilize dois LEDs (verde e vermelho) aplicados a uma única    * 
;*   porta para funcionar em oposição, segundo a notação:		   *
;*     • quando a porta é HIGH → LED1 é ON e LED2 é OFF;		   *
;*     • quando a porta é LOW → LED1 é OFF e LED2 é ON;			   *
;* • Para transição de estado (verde → vermelho ou vermelho → 	   *
;*   verde), ocorrerá após uma contagem decrescente, de 9 até 0;   *
;* • A contagem deve ser indicada em um display de 7 segmentos;	   *
;* • Por se tratar de um semáforo didático, cada transição da 	   *
;*   contagem (indicada no display) deve ocorrer a cada 300 ms.	   *
;*                                                                 *
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
		CONT		;VARIÁVEL DE CONTAGEM
		LOWDELAY	;DELAY PARTE MENOS SIGNIFICATIVA
		HIGHDELAY	;DELAY PARTE MAIS SIGNIFICATIVA
		DISPLAY7	;NUMERO A SER MOSTRADO NO DISPLAY
		DISPLAYINTER	;VARIAVEL INTERMEDIARIA DA ROTINA DISPLAY
		;NOVAS VARIÁVEIS

	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

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
#DEFINE LED  GPIO,GP5		;PORTA DO LED
				; 1 -> LED1 ON; LED2 OFF
				; 0 -> LED1 OFF; LED2 ON 
#DEFINE BIT0 DISPLAYINTER,0	;BITS DO BCD DO DISPLAY
#DEFINE BIT1 DISPLAYINTER,1	
#DEFINE BIT2 DISPLAYINTER,2
#DEFINE BIT3 DISPLAYINTER,4
		    
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
;*	            	 ROTINAS E SUBROTINAS                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.

;DELAY DE 300MS PARA AS TRANSIÇÕES DO CONTADOR
DELAY
	MOVLW	.255
	MOVWF	HIGHDELAY
HIGHLOOP
	MOVLW	.255
	MOVWF	LOWDELAY
LOWLOOP
	DECFSZ	LOWDELAY
	GOTO	LOWLOOP
	DECFSZ	HIGHDELAY
	GOTO	HIGHLOOP
	MOVLW	.135
	MOVWF	HIGHDELAY
HIGHLOOP2
	MOVLW	.255
	MOVWF	LOWDELAY
LOWLOOP2
	DECFSZ	LOWDELAY
	GOTO	LOWLOOP2
	DECFSZ	HIGHDELAY
	GOTO	HIGHLOOP2
	RETURN

;MOSTRAR NUMERO (0 - 9) NO REGITRADOR DISPLAY7 NUM DISPLAY DE 7 SEGMEENTOS
;USANDO OS PINOS GP0, GP1, GP2, GP4 SENDO O GP0 O MENOS SIGNIFICATIVO
;SEGUIDO DO GP1 E GP2, E O GP4 O MAIS SIGNIFICATIVO
;USANDO UMA VARIÁVEL INTERMEDIÁRIA PARA ATUALIZAR O GPIO DE UM SÓ VEZ
DISPLAY
	MOVFW	GPIO		;COPIA TEMPORARIA DE GPIO PARA
	MOVWF	DISPLAYINTER	;NÃO PERDER INFORMAÇÃO DO GPIO
	
	BCF	BIT0		;LIMPA OS BIT DO DISPLAY
	BCF	BIT1	    
	BCF	BIT2
	BCF	BIT3
	
	BTFSC	DISPLAY7,0	;TESTA SE BIT ESTA SETADO
	BSF	BIT0		;SE ESTIVER SETA O BIT DO BCD
	BTFSC	DISPLAY7,1
	BSF	BIT1
	BTFSC	DISPLAY7,2
	BSF	BIT2
	BTFSC	DISPLAY7,3
	BSF	BIT3
	
	MOVFW	DISPLAYINTER	;ATUALIZA ESTADO DO GPIO
	MOVWF	GPIO
	RETURN

	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	B'00000000' ;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISIO		;COMO SAÍDAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O
	MOVLW	B'00000100'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN

				;CORPO DA ROTINA PRINCIPAL
CONTADOR	
	MOVLW	.9		;INICIALIZA VARIAVEL DE CONTAGEM
	MOVWF	DISPLAY7
LOOP1
	CALL	DISPLAY		;MOSTRAR NO DISPLAY
	CALL	DELAY		;DELAY 300 ms
	DECFSZ	DISPLAY7,F
	GOTO	LOOP1
	CALL	DISPLAY		;MOSTRAR NO DISPLAY
	BTFSS	LED		;TESTA SE SAÍDAS DOS LEDS ESTÁ HIGH
	GOTO	OFF
	BCF	LED		;SAÍDA DO LEDS SETADA PARA LOW
	CALL	DELAY		;DELAY 300 ms
	GOTO	CONTADOR
OFF				;SAÍDA DO LED SETADA PARA HIGH
	BSF	LED
	CALL	DELAY		;DELAY 300 ms
	GOTO	CONTADOR	;REPETE PROGRAMA
		
	GOTO MAIN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
