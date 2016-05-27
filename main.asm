;
; 2016 2.zh.asm
;
; Created: 2016.05.26. 13:41:36
; Author : Marci
;


.include "m128def.inc"

.equ mask1 = 0x0F ; maszk a fels� 4 bit null�z�s�hoz
.equ mask2 = 0xF0 ; maszk az als� 4 bit null�z�s�hoz
.equ byte_num = 0x0024
.equ btn_mask = 0x01

.def mpr1 = r16  ; regiszter nevek megad�sa
.def mpr2 = r17
.def mpr3 = r18 ; eredm�ny regiszer

.dseg

mem_space: .byte byte_num ;mem�ria ter�let lefoglal�sa, m�rete:0x24  (0x0100t�l(sram kezdete)-> 0x0124 feladatban legmagasabb �rt�k)

.MACRO Timer0_Init ; macro a timer be�ll�t�s�hoz
	ldi mpr1,@0
	out TCCR0,mpr1
	ldi mpr1,@1
	out OCR0,mpr1
.ENDMACRO

.cseg
.org 0x000

		jmp		init		; Reset vektor 
		jmp		dummy		; EXTINT0 Handler
		jmp		EXTINT1		; EXTINT1 Handler
		jmp		dummy		; EXTINT2 Handler
		jmp		dummy		; EXTINT3 Handler
		jmp		dummy		; EXTINT4 Handler (INT gomb)
		jmp		dummy		; EXTINT5 Handler
		jmp		dummy		; EXTINT6 Handler
		jmp		dummy		; EXTINT7 Handler
		jmp		dummy		; Timer2 Compare Match Handler 
		jmp		dummy		; Timer2 Overflow Handler 
		jmp		dummy		; Timer1 Capture Event Handler 
		jmp		dummy		; Timer1 Compare Match A Handler 
		jmp		dummy		; Timer1 Compare Match B Handler 
		jmp		dummy		; Timer1 Overflow Handler 
		jmp		t0_oc_it	; Timer0 Compare Match Handler 
		jmp		dummy		; Timer0 Overflow Handler 
		jmp		dummy		; SPI Transfer Complete Handler 
		jmp		dummy		; USART0 RX Complete Handler 
		jmp		dummy		; USART0 Data Register Empty Hanlder 
		jmp		dummy		; USART0 TX Complete Handler 
		jmp		dummy		; ADC Conversion Complete Handler 
		jmp		dummy		; EEPROM Ready Hanlder 
		jmp		dummy		; Analog Comparator Handler 
		jmp		dummy		; Timer1 Compare Match C Handler 
		jmp		dummy		; Timer3 Capture Event Handler 
		jmp		dummy		; Timer3 Compare Match A Handler 
		jmp		dummy		; Timer3 Compare Match B Handler 
		jmp		dummy		; Timer3 Compare Match C Handler 
		jmp		dummy		; Timer3 Overflow Handler 
		jmp		dummy		; USART1 RX Complete Handler 
		jmp		dummy		; USART1 Data Register Empty Hanlder 
		jmp		dummy		; USART1 TX Complete Handler 
		jmp		dummy		; Two-wire Serial Interface Handler 
		jmp		dummy		; Store Program Memory Ready Handler 

init:						; Reset megszak�t�s, Stackpointer be�ll�t�sa a ram v�g�re
	ldi mpr1,HIGH(RAMEND)
	out SPH,mpr1
	ldi mpr1,LOW(RAMEND)
	out SPL,mpr1

	ldi YL,LOW(0x0123)  ; SRAM 0x0123 c�me bet�lt�se Y-ba
	ldi YH,HIGH(0x0123)	; m�sodik l�p�s

main:
; Portok be�ll�t�sa:
	ldi mpr1, 0xFF ; C kimenet
	out DDRC,mpr1

	ldi mpr1, 0x00 ; A,B,D bemenet
	out DDRA, mpr1
	out DDRB, mpr1
	out DDRD, mpr1
	out PORTC, mpr1

	Timer0_Init 0x0F,98 ; Timer macro megh�v�sa 2 v�ltoz�val

	ldi mpr1,0x08
	sts EICRA,mpr1
	ldi mpr1,0x02
	out EIMSK,mpr1
	
	sei  ; global interrupt enged�lyez�se
loop:
	ld mpr1,Y ;SRAM 0x0123 c�men l�v� b�jt kiolvas�sa
	andi mpr1,mask2 ; als� 4 bit null�z�sa ( fels� n�gy bit kell)
	swap mpr1  ; als�-fels� 4 bit megcser�l�se
	
	ldd mpr2,Y+1 ;SRAM 0x0124 c�men l�v� b�jt kiolvas�sa
	andi mpr2,mask1 ;fels� 4 bit null�z�sa 
	or mpr1,mpr2 ; 123 �s 124 es b�jt VAGY kapcsolata 
	mov mpr3,mpr1 ;eredm�ny mpr3(r19)-ban
	jmp loop





;  Megszak�t�sok:

EXTINT1: ;gomb k�ls� megszak�t�sa
	push mpr1
	push mpr2
	in mpr1,PORTB
	in mpr2,PORTA 
	bst mpr1,2
	brts Tflag_set
	st Y,mpr1
Tflag_set:
	com mpr1
	st Y,mpr1
	pop mpr2
	pop mpr1
reti

t0_oc_it: ; timer megszak�t�sa (a/iii feladat)  
	push mpr1 ; mpr1 bet�lt�se a veremt�rba
	in mpr1,PORTC ; PortC beolvas�sa
	cpi mpr1,0x00; �sszehasonl�t�s 0-val
	brne next  ; ha nem egyenl� elugrik next-re (branch if not equal)
	out PORTC,mpr3 ;ha PORTC 0 akkor ki�rja mpr3at (SRAM 0x123 �s 0x124 VAGY kapcsolata)
	jmp def
next: 
	ldi mpr1,0x00 
	out PORTC,mpr1 ;ha PORTC nem 0 akkor a kimentet�t 0-ra �ll�tja (Villogtat�s)
def:
	pop mpr1 ;mpr1 visszat�lt�se a veremt�rb�l 
	reti ; interrupt return


dummy: reti