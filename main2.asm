;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
; R4 - counter value
; R5 - 0s debouncing
; R6 - 1s debouncing
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Consts
;-------------------------------------------------------------------------------
LOAD_BUT .set 0x01
INC_BUT  .set 0x01  ;buttons
DEB0_VAL  .set 0x0BFF  ; debouncing 0s(pressed)
DEB1_VAL  .set 0x0BFF  ; debouncing 1s(released)

;-------------------------------------------------------------------------------
; Config
;-------------------------------------------------------------------------------
;---Setting I/O ports-----------------------------------------------------------
	mov.b #0x00, P1DIR	;input(load button)
	mov.b #0x00, P2DIR 	;input(inc button)
	mov.b #0x00, P3DIR	;input(hex switches)
	mov.b #0xff, P4DIR	;output(display)
;---Enabling interrupts---------------------------------------------------------
	bis.b #0x01, &P2IES
    bis.b #0x01, &P2IE
    bis.b #0x01, &P1IES
    bis.b #0x01, &P1IE

;-------------------------------------------------------------------------------
; Init
;-------------------------------------------------------------------------------
    mov.b #0x00, R4  ;setting counter
    mov.b R4, P4OUT  ;displaying
    jmp SLEEP

;-------------------------------------------------------------------------------
; Interrupts
;-------------------------------------------------------------------------------
LOAD_INT:
	bic #CPUOFF|SCG1|SCG0|OSCOFF, 0(SP) ; wake up
	mov.b P3IN, R4
	mov.b R4, P4OUT
	bit.b #LOAD_BUT, P1IN
	jz LOAD_INT
	bic #LOAD_BUT, P1IFG  ; reset of interrupt flag
	bic #INC_BUT, P2IFG
	bit #0x01, R7
	jz EXIT
	bis.b #0x01, R8
EXIT:
	RETI

INC_INT:
	bic #CPUOFF|SCG1|SCG0|OSCOFF, 0(SP) ; wake up
	bic.b #0x01, &P2IE
	bis   #0x01, R7
	EINT
	mov.w #DEB0_VAL, R5
DEBOUNCING0:
	mov.w #DEB1_VAL, R6
	bit.b #INC_BUT,P2IN
	jnz DEBOUNCING1
	dec.w R5
	jnz DEBOUNCING0
INCREMENTATION:
	DINT
	bit.b #0x01, R8
	jnz EXIT_INC
	dadc.b R4
	mov.b R4, P4OUT
EXIT_INC:
	bic.b #0x01, R7
	bic.b #0x01, R8
	bic #INC_BUT, P2IFG  ; reset of interrupt flag
	bic #0x01, R7
	bis.b #0x01, &P2IE
	RETI
DEBOUNCING1:
	mov.w #DEB0_VAL, R5
	bit.b #INC_BUT,P2IN
	jz DEBOUNCING0
	dec.w R6
	jnz DEBOUNCING1
	DINT
	jmp EXIT_INC
;-------------------------------------------------------------------------------
; Main loop
;-------------------------------------------------------------------------------
SLEEP:
	bis #CPUOFF|SCG1|SCG0|OSCOFF|GIE, SR ;EI, LMP4
	NOP
	jmp SLEEP

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            .sect   ".int04"				; high prority interruption(loading)
            .short  LOAD_INT
            .sect   ".int01"				; low priority interruption(incrementation)
            .short  INC_INT
    
