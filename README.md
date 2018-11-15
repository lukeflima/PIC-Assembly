# PIC Assembly
Códigos em assembly para microcontroladores PIC.  
## Descrição dos programas  

### SEMÁFORO DE TRÂNSITO (TrafficSemaphore.ASM)  
 MODELO PARA O **PIC12F675**  
**Especificações:**  
* Utilize dois LEDs (verde e vermelho) aplicados a uma únicaporta para funcionar em oposição, segundo a notação:   
	*  quando a porta é HIGH → LED1 é ON e LED2 é OFF;   
	* quando a porta é LOW → LED1 é OFF e LED2 é ON;   
* Para transição de estado (verde → vermelho ou vermelho → verde), ocorrerá após uma contagem decrescente, de 9 até 0;    
* A contagem deve ser indicada em um display de 7 segmentos;  
* Por se tratar de um semáforo didático, cada transição da contagem (indicada no display) deve ocorrer a cada 300 ms.   
* * * *
### PISCA ALERTA (BlinkerAlert.ASM)
MODELO PARA O **PIC12F675**  
**Especificações:** 
* Um interruptor de 3 posições, para acender 2 LEDs (LED-E e LED-D);   
	* Quando na posição central, o LED-E e o LED-D permanecem apagados;   
	* Quando na posição E (esquerda), o LED-E piscará com frequência de 1 Hz;   
	* Quando na posição D (direita), o LED-D piscará com frequência de 1 Hz;   
* Um interruptor (liga-desliga), para piscar os dois LEDs ao mesmo tempo (função alerta), com frequência de 1 Hz.    Esse interruptor deve ter maior prioridade;   
* GP0 deverá ser utilizado com o interruptor que comandará a função "alerta";   
* GP1 e GP2 deverão ser utilizados para o interruptor de 3 posições;
* GP4 e GP5 deverão ser utilizados, respectivamente, para os LED-E e LED-D.
* * * *
### INFRARED (infrared.ASM)
 MODELO PARA O **PIC12F675**  
**Objetivo**: Implementar um receptor infra-vermelho (IR) que indique a tecla pressionada. *

**Especificações:** 
* O teclado do controle remoto SONY deve ser utilizado para emitir o sinal IR; 
* O protocolo utilizado pela Sony deve ser respeitado;
* A visualização da tecla pressionada (de 0 a 9) deve ser  indicada em um display de 7 segmentos, no kit de bancada; 
* Qualquer outra tecla pressionada deve piscar, com  período de 100 ms, o LED em GP5 
* * * *
### LCD 4 BITS (LCD.ASM)
MODELO PARA O **PIC12F675** 
**Especificações:**  
* Essa aplicação deve ser implementada com o kit disponível no LABEC2, que dispõe de um PIC12F675, um registrador de deslocamento e um LCD (com uma placa desenvolvida por [Gutierrez](https://github.com/gutierrezps)) ; 
![Esquematico placa LCD](https://i.imgur.com/cTeNyUo.png)
* Todas as linhas de controle para o registrador de deslocamento e para o LCD serão gerenciadas pelo PIC; 
* O dado a ser transmitido ao LCD deverá ser enviado para um registrador de deslocamento (shift register – 74164 – ver data sheet); 
* Para que a transmissão do PIC ao shift register ocorra sem erros, as especificações do shift register devem ser obedecidas; 
* Para que o LCD receba os dados corretamente, um procedimentos de inicialização deve ser efetuado e deve obedecer à sequência estabelecida na documentação do LCD (ver data sheet). Como o LCD é um dispositivo "lento", tempos de espera especificados devem ser respeitados; 
* O LCD deve ser configurado para receber dados em grupos de 4 bit; 
* Após o procedimento de inicialização, escreva seu nome no LCD.
* * * *
### MEDIÇÃO DE TENSÃO E INDICAÇÃO EM % DE 5V (percentageADConv.ASM)  
 MODELO PARA O **PIC12F675**   
**Especificações:**  
 • A conversão A/D deve ser feita em 8 bits pela porta GP2;  
 • Faça a aquisição 32 valores para calcular a média de cada medida;  
 • A conversão A/D deve ser efetuada, em modo cíclico e tão rápido quanto possível (limitado pela velocidade do microcontrolador);  
 • O valor da média conversão A/D deve ser transformado para o correspondente percentual de tensão, com 100% correspondendo a 5V;  
 • O valor do percentual da tensão, em notação de base decimal, deve ser visualizado no display LCD;  
 • O valor mostrado no display deve ser atualizado a cada 200 ms;  
 • Faça reuso das suas rotinas desenvolvidas na atividade 2/Av2 para indicação no LCD;  
 • Veja alguns exemplos:  
 
| 	Tensão medida (V) 	|	 Valor mostrado no display 	|
|	:-----------------:	|	:-------------------------:	|
| 	       0,4        	|  	          8 %            	|
| 	       1,8        	|  	          36 %           	|
| 	       2,7        	|  	          54 %           	|
|   	     4,5        	|  	          90 %           	|
|  	      5,0        	|  	         100 %           	|

* * * *
### I2C SLAVE (I2CSLAVEP12F675.ASM e I2CSLAVEP16F628A.asm)  
MODELO PARA O **PIC12F675** e **PIC16F628A**  
**Especificações:**  
* O protocolo I2C deve ser implementado no PIC no modo SLAVE; 
* O PIC deve receber um byte de endereço e sinalizar sua identificação através de um LED; 
* Quando o endereço for identificado como correto, um ACK deve ser enviado e o sinal CLK deve forçado a LOW por 200 ms; 
* Um LED deve indicar que o endereço correto foi recebido, mantendo-o aceso pelo mesmo tempo do ACK em LOW; 
* Para padronizar a utilização das portas, deve ser adotado:   
	* GP0 ou RB7 - SCL   
	* GP1 ou RB6 - SDA   
	* GP5 ou RB5 - LED  
* Endereço do Slave - 0x21  
