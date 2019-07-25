         assume cs:codigo,ds:dados,es:dados,ss:pilha

CR        EQU    0DH ; caractere ASCII "Carriage Return" (tecla ENTER)
LF        EQU    0AH ; caractere ASCII "Line Feed"
BKSPC     EQU    08H ; caractere ASCII "Backspace"
ESCP      EQU    27  ; caractere ASCII "Escape" (tecla ESC)

; SEGMENTO DE DADOS DO PROGRAMA
dados     segment
nome_arq      db 64 dup (?)
meu_nome db 'Guilherme Santana 00301388',CR,LF,'$'
buffer    db 128 dup (?)
pede_arq db 'Nome do arquivo: ','$'
erro      db 'Erro! Repita.',CR,LF,'$'
msg_final db 'Fim do programa.',CR,LF,'$'
erro_velocidade db 'Erro no parametro de alterar a velocidade',CR,LF,'$'
erro_n_existe db 'Arquivo nao encontrado! Por favor, repita.',CR,LF,'$'
erro_caminho db 'Erro no caminho do arquivo',CR,LF,'$'
handler   dw ?
timer_inicial db 0
timer db 0
dez db 10
msg_interronpeu db 'O programa foi interronpido pelo usuario',CR,LF,'$'
msg_continuar db '...precione uma tecla para continuar...',CR,LF,'$'
msg_terminar_enter db 'Programa terminado pelo usuario',CR,LF,'$'
dados     ends

; SEGMENTO DE PILHA DO PROGRAMA
pilha    segment stack            ; permite inicializacao automatica de SS:SP
         dw     128 dup(?)
pilha    ends
         
; SEGMENTO DE CÓDIGO DO PROGRAMA
codigo   segment
inicio:         ; CS e IP sao inicializados com este endereco
         mov    ax,dados           ; inicializa DS
         mov    ds,ax              ; com endereco do segmento DADOS
         mov    es,ax              ; idem em ES
; fim da carga inicial dos registradores de segmento

;-----------INICIO------------
		call limpa_tela
		lea dx,meu_nome		;|
		call write			;|---> printa o nome 
		
		
; pede nome do arquivo		
de_novo: mov timer,0
		 lea    dx,pede_arq       ; endereco da mensagem em DX
         mov    ah,9               ; funcao exibir mensagem no AH
         int    21h                ; chamada do DOS
; le nome do arquivo
         lea    di, nome_arq
entrada: mov    ah,1
         int    21h                ; le um caractere com eco

         cmp    al,ESCP            ; compara com ESCAPE (tecla ESC)
         jne    depois 
         jmp    terminar
depois:
         cmp    al,CR              ; compara com carriage return (tecla ENTER)
         je     continua

         cmp    al,BKSPC           ; compara com 'backspace'
         je     backspace

         mov    [di],al            ; coloca caractere lido no buffer
         inc    di
         jmp    entrada

backspace:
         cmp    di,offset nome_arq
         jne    adiante
         mov    dl,' '              ; avanca cursor na tela
         mov    ah,2
         int    21h
         jmp    entrada
adiante:
         mov    dl,' '              ; apaga ultimo caractere digitado
         mov    ah,2
         int    21h
         mov    dl,BKSPC            ; recua cusor na tela
         mov    ah,2
         int    21h
         dec    di
         jmp    entrada

continua: 
		 cmp di,0
		 jz gambiarra
         mov    byte ptr [di],0     ; forma string ASCIIZ com o nome do arquivo
         mov    dl,LF               ; escreve LF na tela
         mov    ah,2
         int    21h

abre_arq:; abre arquivo para leitura 
         mov    ah,3dh
         mov    al,0
         lea    dx,nome_arq
         int 21h
         jnc    abriu_ok
		 
filtro_erro:
		cmp al,2
		je erro_arq_n_existe
		cmp al,3
		je caminho_n_existe
		lea    dx,erro     		;erro generico
		call write
		jmp de_novo

erro_arq_n_existe:				;erro de nome do arquivo nao encontrado
		lea dx, erro_n_existe
		call write
		jmp de_novo
		
caminho_n_existe:				;erro no caminho do arquivo
		lea dx, erro_caminho
		call write
		jmp de_novo
;----------------------------------------		
gambiarra:
		jmp terminar_enter				
;----------------------------------------
abriu_ok: 
		 mov handler,ax
laco:    
		mov ah,0				;|
		int 1ah					;|->salva o clock inicial
		mov timer_inicial,dl	;|
		
;-----TESTE PRA VER SE R ou N FOI DIGITADA----------
		mov ah,6h
		mov dl,255
		int 21h
		cmp al,'n'
		je interronpeu_novo
		cmp al,'N'
		je interronpeu_novo
		cmp al,'r'
		je interronpeu_repetir
		cmp al, 'R'
		je interronpeu_repetir
		cmp al,ESCP
		je interronpeu_escp
;----------------------------------------------------
		 mov ah,3fh                 ; lê um caractere do arquivo
         mov bx,handler
         mov cx,1
         lea dx,buffer
         int 21h
         cmp ax,cx
         jne fim
		 
		 cmp buffer,'#'			;testa pra ver se tem q mudar a velocidade
		 jne segue
		 call muda_velocidade
		 
		
segue:
		call tempo
		
         mov dl, buffer             ; escreve caractere na tela
         mov ah,2
         int 21h
		jmp laco
		
		
interronpeu_novo:				;|Quando for digitado N vai
		call limpa_tela			;|pro inicio onde pede o nome do arquivo
		jmp de_novo				;|

		
interronpeu_repetir:	;|Recomeça a printar o mesmo arquivo q ja tinha 
		call limpa_tela			;|sido aberto anteriormtente 
		mov timer,0				;|
		jmp abre_arq			;|
		
interronpeu_escp:
		call limpa_tela
		lea dx,msg_interronpeu
		call write
		lea dx,msg_continuar
		call write
		call espera_tecla


fim:     mov ah,3eh                 ; fecha arquivo
         mov bx,handler
         int 21h
		
		 call limpa_tela
         lea    dx,msg_final        ;|printa mensagem final e 
         mov    ah,9                ;|printa mensagem de aguardo de uma tecla
         int    21h					;|
		 lea dx,msg_continuar		;|quando alguma tecla é precionada, limpa a 
		 mov ah,9					;|tela e volta para o inicio pedindo um nome 
		 int 21h					;|de um novo arquivo, reniciando tudo
		 call espera_tecla			;|
		 call limpa_tela			;|
		 jmp de_novo				;|

terminar_enter:
		call limpa_tela
		lea dx,msg_terminar_enter
		call write
		
terminar:
		
         mov    ax,4c00h            ; funcao retornar ao DOS no AH
                                    ; codigo de retorno 0 no AL
         int    21h                 ; chamada do DOS
;----------------------------------------------------------------
;							SUBROTINAS
;----------------------------------------------------------------

write proc		;|
	mov ah,9	;|
	int 21h		;|--->escreve na tela( dx aponta para o inicio da mensagem)
	ret			;|
write endp		;|

espera_tecla proc	;|
	mov ah,8		;|
	int 21h			;|---> espera uma tecla ser digitada para seguir 
	ret				;|
espera_tecla endp	;|

muda_velocidade proc
		mov ah,3fh
		mov bx,handler
		mov cx,1
		lea dx,buffer
		int 21h
		
		cmp buffer,'9'		;|controle de entrada para pegar so os 
		ja fim_erro			;|numeros de 0 a 9
		cmp buffer,'0'		;|
		jb fim_erro			;|
		sub buffer,'0'
		mov dl,buffer		;|dl->registrador intermediario
		mov timer,dl		;|
		
		
;----------multiplicaçao por 10----------
		mov al,timer
		mul dez
		mov timer,al
;----------------------------------------
		mov ah,3fh
		mov bx,handler
		mov cx,1
		lea dx,buffer
		int 21h
		
		cmp buffer,'9'		;|controle de entrada para pegar so os 
		ja fim_erro			;|numeros de 0 a 9
		cmp buffer,'0'		;|
		jb fim_erro			;|
		sub buffer,'0'		;|
		mov dl,buffer		;|dl->registrador intermediario
		add timer,dl		;|
		
		mov ah,3fh			;|ja deixa o buffer com
		mov bx,handler		;|o proximo caractere
		mov cx,1			;|que tem que ser
		lea dx,buffer		;|escrito
		int 21h				;|
		
		ret
fim_erro:
			call limpa_tela
			
			lea dx,erro_velocidade	
			call write				
			call espera_tecla	
			
			jmp fim
		ret
muda_velocidade endp

tempo proc
tic_tac:
	mov ah,0						;|
	int 1ah							;|->dx tem o timer_final
	sub dl,timer_inicial			;|->faz a diferença dos tempo
	cmp dl,timer					;|->compara se essa diferença é igual ou maior ao timer passado 
	jnae tic_tac					;|se não for maior ou igual volta pro loop
	ret								;|
tempo endp

limpa_tela proc
;------------LIMPA A TELA -------------------
			mov ch,0
			mov cl,0
			mov dh,24
			mov dl,79
			mov bh,0AH		;muda a cor pra fundo preto e letra verde
			mov al,0
			mov ah,6
			int 10h
			
			
			mov dh,0	;|
			mov dl,0	;|
			mov bh,0	;|--> MOVE O CURSOR PARA O INICIO
			mov ah,2	;|
			int 10h		;|
			ret
limpa_tela endp
codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve começar a execucao no rotulo "inicio"
         end    inicio 

