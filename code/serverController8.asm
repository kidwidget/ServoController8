	; atmega88pa
	; 18.432 MHz
	; spi - slave mode, fclk/16, MSB first
	;	sample rising edge, set up falling edge
	;
	; to use:
	;	two byte packets, first byte is servo number 
	;	second byte is position
	;	server number = 0 to 7
	;	position = 0 - 254
	; 
	;	in the spi interrupt routine uncomment:
	;		cpi spidata, 255
	;		breq reset
	;	to allow the value 255 to be used to 
	;	reset the software. Otherwise don't 
	;	use the value 255. This software doesn't
	;	provide error checking.
	;
	; LSB = least significant byte
	; MSB = most signifacant byte
	;
	; uncomment the next line if using Atmel Studio 4
	; .include	"m88def.inc"

	.def	temp = r16
	.def	spiData = r17
	.def	resolutionCounter = r18
	.def	flags = r19	
	; flags:
	; bit0 - spia, 0 spi not received / 1 spi received
	; bit1 - spib, 0 LSB ready / 1 MSB ready
	; bit2 - UNDEFINED
	; bit3 - UNDEFINED
	; bit4 - UNDEFINED
	; bit5 - UNDEFINED
	; bit6 - UNDEFINED
	; bit7 - UNDEFINED
	.def	pointerBuffer = r20		

	.equ	spiaMask	=	0b00000001	
	.equ 	spiaBit		=	0
	.equ	spibMask	=	0b00000010
	.equ	spibBit		=	1
	.equ	servoPorta	=	portd
	.equ	resolution	=	8
	.equ	_1mSecWait	=	2303
	.equ	_18mSecWait	=	41471

	.cseg

	.org 0x00
	rjmp reset					; Reset
	; rjmp reset				; int0
	; rjmp reset				; int1
	; rjmp reset				; pcint0
	; rjmp reset				; pcint1
	; rjmp reset				; pcint2
	; rjmp reset				; wdt
	; rjmp reset				; timer2compA
	; rjmp reset				; timer2compB
	; rjmp reset				; timer2ovf
	; rjmp reset				; timer1capt
	.org 0x0b
	rjmp int_timer1compA		; timer1compA
	rjmp int_timer1compB		; timer1compB
	; rjmp reset				; timer1Ovf
	; rjmp reset				; timer0compA
	; rjmp reset				; timer0compB
	; rjmp reset				; timer0ovf
	.org 0x11
	rjmp int_spi				; spi
	; rjmp reset				; usart rx
	; rjmp reset				; usart udre
	; rjmp reset				; usart tx
	; rjmp reset				; adc
	; rjmp reset				; eeReady
	;c
	;o reset
	reset:
		; initialize stack
		ldi temp, low(ramend)
		out spl, temp
		ldi temp, high(ramend)
		out sph, temp

		; set portd for all output
		ldi temp, 0xff
		out ddrd, temp
		
		; enable global interupts
		sei				
		; initialize timer1
		ldi temp, (1<<wgm12)|(1<<cs11)		; clear timer on compare match, fclk/8
		sts tccr1b, temp
		ldi temp, (1<<ocie1a)			; compA enabled
		sts timsk1, temp
		
		; initialize spi
		ldi temp, (1<<PB4)
		out DDRB, temp
		ldi temp, (1<<spie)|(1<<spe)|(1<<spr0)	 
		out spcr, temp				

	prime:
		ldi temp, high(_1mSecWait)		; load timer/counter1 compare registers
		sts ocr1ah, temp 
		ldi temp, low(_1mSecWait)
		sts ocr1al, temp
		ldi temp, high(_18mSecWait)
		sts ocr1bh, temp
		ldi temp, low(_18mSecWait)
		sts ocr1bl, temp
		
		ldi r27, 0x01				; all servos at center
		ldi temp, 127
		st x+, temp
		st x+, temp
		st x+, temp
		st x+, temp
		st x+, temp
		st x+, temp
		st x+, temp
		st x, temp
		ldi r26, 0x00
		
		ldi temp, 0xff
		out servoPorta, temp

	main:
		sbrc flags, spiaBit
			rcall parse
		rjmp main

	parse:
		cbr flags, spiaMask
		sbrc flags, spibBit			; if LSB then set pointer to table,
			rjmp storeData 			; else store data in table
		mov pointerBuffer, spidata
		sbr flags, spibMask
		ret
		storeData:
			cli
			mov r26, pointerBuffer
			st x, spidata
			sei
			; ldi r26, 0x00			; restore pointer 
			cbr flags, spibMask
			ret
	int_spi:
		in spiData , spdr			; move data into register, then flip flag bit
		; cpi spiData, 255			; send 255 to reset
		; breq reset
		sbr flags, spiaMask	
		reti

	int_timer1compA:
		ldi temp, high(resolution)
		sts ocr1ah, temp
		ldi temp, low(resolution)		; set resolution to 1/256 mSecs
		sts ocr1al, temp			
		cpi resolutionCounter, 255		; after 2mSecs goto 18 mSecs wait mode
		breq compAoff

	servoOut:
		servo0:
			ld temp, x+
			cpse temp, resolutionCounter
			rjmp servo1
			cbi servoPorta, 0
		servo1:
			ld temp, x+
			cpse temp, resolutionCounter
			rjmp servo2
			cbi servoPorta, 1
		servo2:
			ld temp, x+
			cpse temp, resolutionCounter
			rjmp servo3
			cbi servoPorta, 2
		servo3:
			ld temp, x+
			cpse temp, resolutionCounter
			rjmp servo4
			cbi servoPorta, 3
		servo4:
			ld temp, x+
			cpse temp, resolutionCounter
			rjmp servo5
			cbi servoPorta, 4
		servo5:
			ld temp, x+
			cpse temp, resolutionCounter
			rjmp servo6
			cbi servoPorta, 5
		servo6:
			ld temp, x+
			cpse temp, resolutionCounter
			rjmp servo7
			cbi servoPorta, 6
		servo7:
			ld temp, x
			cpse temp, resolutionCounter
			rjmp serovOutCleanUp
			cbi servoPorta, 7
			serovOutCleanUp:
				ldi r26, 0x00		; restore xpointer to beginning of sram		
		inc resolutionCounter
		reti
		compAoff:
			inc resolutionCounter
			ldi temp, 0xff
			sts ocr1ah, temp
			sts ocr1al, temp
			ldi temp, (1<<ocie1B)		; compareA is now off
			sts timsk1, temp
			reti

	int_timer1compB:
		ldi temp, 0x00
		sts tcnt1h, temp
		sts tcnt1l, temp
		ldi temp, (1<<ocie1A)			; turn compareA back on
		sts timsk1, temp
		ldi temp, high(_1mSecWait)		; restore compareA to 1mSecWait
		sts ocr1ah, temp 
		ldi temp, low(_1mSecWait)
		sts ocr1al, temp
		ldi temp, 0xff				; pull all servo's high
		out servoPorta, temp
		reti
		

