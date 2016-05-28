;
; 2015 2.zh B csoport
;
; Created: 2016.05.22. 15:08:54
; Author : Marci
;


.include "m128def.inc"
.equ byte_num = 50

.def mpr1 = r16
.def mpr2 = r17
.def byte_cnt = r18
.def temp = r19

.dseg
mem_space: .byte byte_num ; SRAM els� 50 c�m�nek lefoglal�sa

.MACRO Timer0_Init ; Timer macro
	ldi mpr1,@0 ; els� param�ter bet�lt�se mpr1-be
	out TCCR0,mpr1 ; mpr1 bet�lt�se TCCR0 regiszterbe. CTC m�d, 1024 el�oszt�s
	ldi mpr1,@1 ; m�sodik param�ter bet�lt�se mpr2-be
	out OCR0, mpr1 ; mpr1 bet�lt�se OCR0 regiszerbe.
.ENDMACRO

.cseg
.org 0x0000

		jmp		init		; Reset vektor 
		jmp		dummy		; EXTINT0 Handler
		jmp		dummy		; EXTINT1 Handler
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

init: 
	ldi mpr1,HIGH(RAMEND) ; Stack inicializ�l�sa
	out SPH,mpr1
	ldi mpr1,LOW(RAMEND)
	out SPL,mpr1

	ldi XL,LOW(mem_space) ; mem_space c�m�nek bet�lt�se X-regiszerbe
	ldi XH,HIGH(mem_space) ; m�sodik l�p�s
	ldi temp,0x00
main:
	ldi mpr1,0x00 ; Portok be�ll�t�sa
	out DDRC,mpr1 ; PORTC bemeet
	ldi mpr1,0xFF
	out DDRB,mpr1 ; PORTB kimenet
	ldi mpr1,0x00
	out PORTB,mpr1 ; PORTB kimenetre 0

		; 1024 prescaler, CTC mode (clear on compare match) OC0 disconnected
		; TCCR0: FOC0 WGM00 COM01 CM00 WGM01 CS02 CS01 CS00
		;         0    0    0     0     1     1    1    1
		; f = 4000000/(1024*28) = 139,50 Hz 

	Timer0_Init 0x0F,28 ; Macro timer
	ldi byte_cnt,byte_num ; byte_cnt felt�lt�se 50-el a forciklushoz

loop:
	in mpr1,PORTC ;PORTC beolvas�sa
	cpi mpr1,0x22 ; �sszehasonl�t�s 0x22-vel
	brne next ;ha nem egyenl� akkor ugrik nextre
	ldi mpr2,0x00
	ldi temp,0x00 ;temp felt�lt�se 0x00-val

FOR1:
	st X+,temp ; X aktu�lis c�m�nek felt�lt�se 0x00-val, X n�vel�se
	st X+,mpr2 ; X aktu�lis c�m�nek felt�lt�se mpr2vel (ezt fogjuk n�velni), X n�vel�se a k�vetkez� c�mre
	inc mpr2 ; mpr2 n�vel�se (increment)
	dec byte_cnt ; byte_cnt cs�kkent�se (decrement)
	brne FOR1 ; ha byte_cnt el�rte a null�t akkor nem ugrik FOR1-re(lefutott �tvenszer)
	jmp def ; ugr�s defre

next:
	cpi mpr1,0x11 ; �sszehasonl�t�s 0x11-el
	brne def ;ha nem egyenl� ugrik def-re
	lds mpr1,0x100 ;SRAM els� hely�n l�v� c�m bet�lt�se mpr2-be
	lds mpr2,0x101 ;SRAM m�sodik hely�n l�v� c�m bet�lt�se mpr2-be
	or mpr1,mpr2 ; VAGY kapcsolat
	out PORTA,mpr1 ;eredm�ny PORTA-n

	lds mpr1,0x102 ; el�z� megism�telve az SRAM m�sodik k�t �rt�k�vel
	lds mpr2,0x103
	or mpr1,mpr2
	out PORTB,mpr1 ;eredm�ny PORTB-n
	sei ; global interrupt enged�lyz�se, a timer megszak�t�s�hoz
jmp loop ; jump loop, am�g PORTC = 0x11 addig nem fut le a def 

def:
	cli ; golbal interrupt letilt�sa(clear I-flag)
jmp loop ; jump loop

t0_oc_it: ;timer megszak�t�sa
	push mpr1
	push mpr2 ; mpr1 �s mpr2 veremt�rba t�lt�se
	ldi mpr1,PORTA
	ldi mpr2,PORTB ; PORTA (SRAM els� k�t c�m�nek VAGY kapcsolata) �s PORTB (SRAM m�sodik k�t c�m�nek VAGY kapcsolata) beolvas�sa mpr1 �s mpr2-be
	cpi temp,0xFF ;temp �sszehasonl�t�sa 0xFF-el(els� lefut�sra temp = 0x00)
	brne next2 ; ha nem egyenl� akkor ugrik next2-re
	out PORTD,mpr1 ; mpr1 ki�r�sa PORTD-re
	ldi temp,0x00 ; temp felt�lt�se 0x00-val
	jmp def2 ; ugr�s def2
next2:
	out PORTD,mpr2 ; mpr2 ki�r�sa PORTD-re
	ldi temp,0xFF ; temp felt�lt�se 0xFFel
def2:
	pop mpr2
	pop mpr1 ; mpr2 �s mpr1 visszat�lt�se a veremt�rb�l
reti ; interrupt return

dummy: reti