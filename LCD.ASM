;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       	LCD 4 BITS		                       *
;*								  							       *
;*	       		DESENVOLVIDO POR LUCAS FERREIRA LIMA		   	   *
;*			 		     DATA: 18/10/18			  				   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   MODELO PARA O PIC 12F675                                	   *
;* Especificações:												   *
;* • Essa aplicação deve ser implementada com o kit disponível	   * 
;*   no LABEC2, que dispõe de um PIC12F675, um registrador de 	   *
;*   deslocamento e um LCD;										   *
;* • Todas as linhas de controle para o registrador de 			   *
;*   deslocamento e para o LCD serão gerenciadas pelo PIC;	   	   *
;* • O dado a ser transmitido ao LCD deverá ser enviado para 	   *
;*   um registrador de deslocamento (shift register – 74164);	   *
;* • Para que a transmissão do PIC ao shift register ocorra sem	   *
;*   erros, as especificações do shift register devem ser 		   *
;*   obedecidas;												   *
;* • Para que o LCD receba os dados corretamente, um procedimentos *
;*   de inicialização deve ser efetuado e deve obedecer à sequência*
;*   estabelecida na documentação do LCD (ver data sheet). Como o  *
;*   LCD é um dispositivo "lento", tempos de espera especificados  *
;*   devem ser respeitados;										   *
;* • O LCD deve ser configurado para receber dados em grupos 	   *
;*   de 4 bit;													   *
;* • Após o procedimento de inicialização, escreva seu nome no LCD.*
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
		
		CONT
		TIME
		THIGH
		;  7   6   5    4   3    2    1    0
 		;| * | * | BL | RS | D4 | D5 | D6 | D7 |
		SHIFT		;VARIAVEL A SER PASSADA PARA O SHIFTREG
		SHIFT_CONT	;CONTADOR AUXILIAR P SUBROTINA DO SHIFTREG
		
		;  7   6   5    4   3    2    1    0
 		;| DB7 | DB6 | DB5 | DB4 | DB3 | DB2 | DB1 | DB0 |
		CMD		;USADA PARA MANDAR COMANDO PARA LCD
		AUX		;VARIAVEL AUXILIAR
		BYTE		;USADA PARA INVERTER BYTE
		
		CONTEXT		;VARIAVEL DE CONTEXTO
				;BIT 0 - BACKLIGHT
	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA
#DEFINE BACKLIGHT CONTEXT,0
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
#DEFINE SRCLK	GPIO, GP0
#DEFINE LCD_EN	GPIO, GP5
#DEFINE	SRDAT	GPIO, GP4
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

;MOVE BYTE NO WORK PARA O REGISTRADOR DE DESLOCAMENTO
SHIFT_REG
	MOVWF	SHIFT
	MOVLW	.8
	MOVWF	SHIFT_CONT
SHIFT_LOOP
	BCF	SRDAT	    ;LIMPA BIT DE ENVIO DE DADO, SE ULTIMO BIT
	BTFSC	SHIFT, 0    ;ESTIVER EM 1, SETA BIT DE ENVIO
	BSF	SRDAT
	BSF	SRCLK	    ;PULSA CLOCK
	BCF	SRCLK
	RRF	SHIFT, F    ;ROTACIONA PARA O PROXIMO BIT
	DECFSZ	SHIFT_CONT  ;REPERE POR 8 VEZES
	GOTO	SHIFT_LOOP

	RETURN

;FUNÇÃO PARA PULSO DO ENABLE
SEND_INPUT
	BSF	LCD_EN
	BCF	LCD_EN
	
	RETURN
	
DELAY_40US
	MOVLW	.7
	MOVWF	CONT
DELAY_INTER
	NOP
	NOP
	DECFSZ	CONT,F
	GOTO	DELAY_INTER
	
	RETURN
HERE

;DELAY DE MAIS DE  (WORK*100)uS
DELAY_TMR1
	MOVWF	TIME
	CLRF	THIGH
	MOVLW	.100
	MOVWF	CONT
	MOVFW	TIME
	ADDWF	TIME,F
	BTFSC	STATUS,C
	INCF	THIGH,F
	DECFSZ	CONT
	GOTO	$-4
	INCF	THIGH
	SUBWF	TIME,F
	COMF	TIME,F
	INCF	TIME,F
	COMF	THIGH,F
	MOVFW	THIGH
	MOVWF	TMR1H
	MOVFW	TIME
	MOVWF	TMR1L
	BCF	PIR1, TMR1IF
	BTFSS	PIR1, TMR1IF
	GOTO	$-1
	
	RETURN

DELAY_100US
	MOVLW	.40
	MOVWF	CONT

	NOP
	NOP
	DECFSZ	CONT,F
	GOTO	$-3
				
	RETURN

;INVERTE BITS DO BYTE
;BYTE RECEBIDO PELO WORK
INVERT_BYTE
	MOVWF	BYTE		
	MOVLW	.8
	MOVWF	CONT
	RRF	BYTE	    ;ROTACIONA BIT MAIS A DIREITA PARA O CARRY
	RLF	AUX	    ;PEGAR BIT DO CARRY E ROTACIONA PARA A POSIÇÃO
	DECFSZ	CONT	    ;MAIS A DIREITA, ASSIM INVERTENDO O BYTE
	GOTO	$-3
	MOVFW	AUX
	RETURN
;MANDA COMANDO PARA O DIPLAY
;CMD RECEBIDO PELO WORK	
SEND_CMD
	CALL	INVERT_BYTE	;INVERTE BYTE PARA ACOMODAR ARQUITETURA
	MOVWF	CMD		;DA PLACA
	MOVLW	.15
	ANDWF	CMD,W		;SELECIONA OS 4 PRIMEIRO BITS PARA ENVIAR
	MOVWF	AUX
	BTFSC	BACKLIGHT	;ATIVA BACKLIGHT SE ESTIVER ATIVO
	BSF	AUX,5
	MOVFW	AUX
	CALL	SHIFT_REG	;MOVE PARA O REGISTRADOR
	CALL	SEND_INPUT	;MANDA ENABLE PARA LCD
	SWAPF	CMD,F		;SWAP PARA PEGAR OS OUTRO 4 BITS
	MOVLW	.15
	ANDWF	CMD,W
	MOVWF	AUX
	BTFSC	BACKLIGHT	;ATIVA BACKLIGHT SE ESTIVER ATIVO
	BSF	AUX,5
	MOVFW	AUX
	CALL	SHIFT_REG	;MOVE PARA O REGISTRADOR
	CALL	SEND_INPUT	;MANDA ENABLE PARA LCDs
	CALL	DELAY_100US
	
	RETURN
;MANDA CHAR PARA O DIPLAY
;CHAR RECEBIDO PELO WORK
SEND_CHAR
	CALL	INVERT_BYTE	;INVERTE BYTE PARA ACOMODAR ARQUITETURA
	MOVWF	CMD		;DA PLACA
	MOVLW	.15
	ANDWF	CMD,W		;SELECIONA OS 4 PRIMEIRO BITS PARA ENVIAR
	MOVWF	AUX		
	BSF	AUX,4		;ATIVA O RS DO DISPLAY
	BTFSC	BACKLIGHT	;ATIVA BACKLIGHT SE ESTIVER ATIVO
	BSF	AUX,5
	MOVFW	AUX
	CALL	SHIFT_REG	;MOVE PARA O REGISTRADOR
	CALL	SEND_INPUT	;MANDA ENABLE PARA LCD
	SWAPF	CMD,F		;SWAP PARA PEGAR OS OUTRO 4 BITS
	MOVLW	.15
	ANDWF	CMD,W
	MOVWF	AUX
	BSF	AUX,4
	BTFSC	BACKLIGHT	;ATIVA BACKLIGHT SE ESTIVER ATIVO
	BSF	AUX,5
	MOVFW	AUX
	CALL	SHIFT_REG	;MOVE PARA O REGISTRADOR
	CALL	SEND_INPUT	;MANDA ENABLE PARA LCD
	CALL	DELAY_100US
	
	RETURN

INIT_LCD
	MOVLW	.150
	CALL	DELAY_TMR1
	MOVLW	B'00001100'	;INSTRUÇÃO DE FUNCTION SET
	CALL	SHIFT_REG
	CALL	SEND_INPUT
	
	MOVLW	.41
	CALL	DELAY_TMR1
	MOVLW	B'00001100'	;INSTRUÇÃO DE FUNCTION SET
	CALL	SHIFT_REG
	CALL	SEND_INPUT
	
	MOVLW	B'00001100'	;INSTRUÇÃO DE FUNCTION SET
	CALL	SHIFT_REG
	CALL	SEND_INPUT
	CALL	DELAY_100US
	
	MOVLW	B'00000100'	;INSTRUÇÃO DE FUNCTION SET
	CALL	SHIFT_REG	;DEFINIR COMUNICAÇÃO 4BITS
	CALL	SEND_INPUT
	CALL	DELAY_100US

	MOVLW	B'00101000'	;INSTRUÇÃO DE FUNCTION SET
	CALL	SEND_CMD	;ESPECIFICA DISPLAY DE 2 SEGMENTO
				;FONTE 5X7

	MOVLW	B'00001100'	;LIGA DISPLAY
	CALL	SEND_CMD
	
	MOVLW	B'00000001'	;LIMPA DISPLAY
	CALL	SEND_CMD
	
	MOVLW	.16
	CALL	DELAY_TMR1
	
	MOVLW	B'00000110'	;INSTRUÇÃO DE FUNCTION SET
	CALL	SEND_CMD
	
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
	MOVLW	B'00000001'	;TMR1 PRESCALE 1:1
	MOVWF	T1CON
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	CLRF	GPIO
	BSF	BACKLIGHT	;ATIVABACKLIGHT
	CALL	INIT_LCD	;INICIALIZA LCD COM INTEFACE DE 4 BITS
	MOVLW	A'L'		;ENVIA Lucas PARA LCD
	CALL	SEND_CHAR	
	MOVLW	A'u'	
	CALL	SEND_CHAR	
	MOVLW	A'c'	
	CALL	SEND_CHAR
	MOVLW	A'a'	
	CALL	SEND_CHAR
	MOVLW	A's'	
	CALL	SEND_CHAR
	
	MOVLW	B'11000100'	;MUDA PARA SEGUNDA LINHA, 4ª LETRA
	CALL	SEND_CMD
	MOVLW	A'L'		;ENVIA Lima PARA LCD
	CALL	SEND_CHAR	
	MOVLW	A'i'	
	CALL	SEND_CHAR	
	MOVLW	A'm'	
	CALL	SEND_CHAR
	MOVLW	A'a'	
	CALL	SEND_CHAR
MAIN
	GOTO	MAIN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
