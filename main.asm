;
; 2016 2.zh.asm
;
; Created: 2016.05.26. 03:41:36
; Author : Marci
;


.include "m128def.inc"

.equ mask1 = 0x0F ; maszk a felsõ 4 bit nullázásához
.equ mask2 = 0xF0 ; maszk az alsó 4 bit nullázásához
.equ byte_num = 0x0024
.equ btn_mask = 0x01

.def mpr1 = r16  ; regiszter nevek megadása
.def mpr2 = r17
.def mpr3 = r18 ; eredmény regiszer

.dseg

mem_space: .byte byte_num ;memória terület lefoglalása, mérete:0x24  (0x0100tól(sram kezdete)-> 0x0124 feladatban legmagasabb érték)

.MACRO Timer0_Init ; macro a timer beállításához
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

init:						; Reset megszakítás, Stackpointer beállítása a ram végére
	ldi mpr1,HIGH(RAMEND) 
	out SPH,mpr1
	ldi mpr1,LOW(RAMEND)
	out SPL,mpr1

	ldi YL,LOW(0x0123)  ; SRAM 0x0123 címe betöltése Y-ba
	ldi YH,HIGH(0x0123)	; második lépés

main:
; Portok beállítása:
	ldi mpr1, 0xFF ; C kimenet
	out DDRC,mpr1

	ldi mpr1, 0x00 ; A,B,D bemenet
	out DDRA, mpr1
	out DDRB, mpr1
	out DDRD, mpr1
	out PORTC, mpr1

	Timer0_Init 0x0F,98 ; Timer macro meghívása 2 változóval

	ldi mpr1,0x08
	sts EICRA,mpr1
	ldi mpr1,0x02
	out EIMSK,mpr1 ; külsõ megszakítás beállítása
	
	sei  ; global interrupt engedélyezése
loop:
	ld mpr1,Y ;SRAM 0x0123 címen lévõ bájt kiolvasása
	andi mpr1,mask2 ; alsó 4 bit nullázása ( felsõ négy bit kell)
	swap mpr1  ; alsó-felsõ 4 bit megcserélése
	
	ldd mpr2,Y+1 ;SRAM 0x0124 címen lévõ bájt kiolvasása
	andi mpr2,mask1 ;felsõ 4 bit nullázása 
	or mpr1,mpr2 ; 123 és 124 es bájt VAGY kapcsolata 
	mov mpr3,mpr1 ;eredmény mpr3(r19)-ban
	jmp loop





;  Megszakítások:

EXTINT1: ;gomb külsõ megszakítása
	push mpr1 
	push mpr2 ; mpr1/2 aktuális értéke betöltése a veremtárba
	ldi mpr1,SREG ; SREG értéke betöltése mpr1-be
	push mpr1 ; SREG értéke a veremtárba

	in mpr1,PORTB 
	in mpr2,PORTA ; PORTA-B beoasása
	bst mpr1,2 ; PORTB 3-ik láb értékének ellenõrzése; Ha 1 akkor a T flag értéke 1 lesz, ha 0 akkor T flag 0
	brts Tflag_set ; Branch if T flag set, ugrik ha T=1
	st Y,mpr2  ; SRAM 0x0123-as címének feltöltése PORTA ponált értékével
	jmp exit
Tflag_set:
	com mpr2 ; PORTA negálása
	st Y,mpr2 ; SRAM 0x0123-as címének feltöltése PORTA negált értékével
exit:
	pop mpr1 ; SREG értéke kiolvasása a veremtárból
	out SREG,mpr1 ; SREG visszaírása
	pop mpr2 ; mpr2 visszatöltése
	pop mpr1 ; mpr1 visszatöltése
reti

t0_oc_it: ; timer megszakítása (a/iii feladat)  
	push mpr1 ; mpr1 betöltése a veremtárba
	ldi mpr1,SREG ; SREG betöltése mpr1-be mivel a státusz regisztereket is használjuk
	push mpr1 ; mpr1(SREG) veremtárba
	in mpr1,PORTC ; PortC beolvasása
	cpi mpr1,0x00; összehasonlítás 0-val
	brne next  ; ha nem egyenlõ elugrik next-re (branch if not equal)
	out PORTC,mpr3 ;ha PORTC 0 akkor kiírja mpr3at (SRAM 0x123 és 0x124 VAGY kapcsolata)
	jmp exit2
next: 
	ldi mpr1,0x00 
	out PORTC,mpr1 ;ha PORTC nem 0 akkor a kimentetét 0-ra állítja (Villogtatás)
exit2:
	pop mpr1 ;mpr1 visszatöltése a veremtárból (SREG értéke elõször)
	out SREG,mpr1 ; mpr1 SREG-be
	pop mpr1 ;mpr1 visszatöltése
	reti ; interrupt return


dummy: reti