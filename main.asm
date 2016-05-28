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
mem_space: .byte byte_num ; SRAM elsõ 50 címének lefoglalása

.MACRO Timer0_Init ; Timer macro
	ldi mpr1,@0 ; elsõ paraméter betöltése mpr1-be
	out TCCR0,mpr1 ; mpr1 betöltése TCCR0 regiszterbe. CTC mód, 1024 elõosztás
	ldi mpr1,@1 ; második paraméter betöltése mpr2-be
	out OCR0, mpr1 ; mpr1 betöltése OCR0 regiszerbe.
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
	ldi mpr1,HIGH(RAMEND) ; Stack inicializálása
	out SPH,mpr1
	ldi mpr1,LOW(RAMEND)
	out SPL,mpr1

	ldi XL,LOW(mem_space) ; mem_space címének betöltése X-regiszerbe
	ldi XH,HIGH(mem_space) ; második lépés
	ldi temp,0x00
main:
	ldi mpr1,0x00 ; Portok beállítása
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
	ldi byte_cnt,byte_num ; byte_cnt feltöltése 50-el a forciklushoz

loop:
	in mpr1,PORTC ;PORTC beolvasása
	cpi mpr1,0x22 ; összehasonlítás 0x22-vel
	brne next ;ha nem egyenlõ akkor ugrik nextre
	ldi mpr2,0x00
	ldi temp,0x00 ;temp feltöltése 0x00-val

FOR1:
	st X+,temp ; X aktuális címének feltöltése 0x00-val, X növelése
	st X+,mpr2 ; X aktuális címének feltöltése mpr2vel (ezt fogjuk növelni), X növelése a következõ címre
	inc mpr2 ; mpr2 növelése (increment)
	dec byte_cnt ; byte_cnt csökkentése (decrement)
	brne FOR1 ; ha byte_cnt elérte a nullát akkor nem ugrik FOR1-re(lefutott ötvenszer)
	jmp def ; ugrás defre

next:
	cpi mpr1,0x11 ; összehasonlítás 0x11-el
	brne def ;ha nem egyenlõ ugrik def-re
	lds mpr1,0x100 ;SRAM elsõ helyén lévõ cím betöltése mpr2-be
	lds mpr2,0x101 ;SRAM második helyén lévõ cím betöltése mpr2-be
	or mpr1,mpr2 ; VAGY kapcsolat
	out PORTA,mpr1 ;eredmény PORTA-n

	lds mpr1,0x102 ; elõzõ megismételve az SRAM második két értékével
	lds mpr2,0x103
	or mpr1,mpr2
	out PORTB,mpr1 ;eredmény PORTB-n
	sei ; global interrupt engedélyzése, a timer megszakításához
jmp loop ; jump loop, amíg PORTC = 0x11 addig nem fut le a def 

def:
	cli ; golbal interrupt letiltása(clear I-flag)
jmp loop ; jump loop

t0_oc_it: ;timer megszakítása
	push mpr1
	push mpr2 ; mpr1 és mpr2 veremtárba töltése
	ldi mpr1,PORTA
	ldi mpr2,PORTB ; PORTA (SRAM elsõ két címének VAGY kapcsolata) és PORTB (SRAM második két címének VAGY kapcsolata) beolvasása mpr1 és mpr2-be
	cpi temp,0xFF ;temp összehasonlítása 0xFF-el(elsõ lefutásra temp = 0x00)
	brne next2 ; ha nem egyenlõ akkor ugrik next2-re
	out PORTD,mpr1 ; mpr1 kiírása PORTD-re
	ldi temp,0x00 ; temp feltöltése 0x00-val
	jmp def2 ; ugrás def2
next2:
	out PORTD,mpr2 ; mpr2 kiírása PORTD-re
	ldi temp,0xFF ; temp feltöltése 0xFFel
def2:
	pop mpr2
	pop mpr1 ; mpr2 és mpr1 visszatöltése a veremtárból
reti ; interrupt return

dummy: reti