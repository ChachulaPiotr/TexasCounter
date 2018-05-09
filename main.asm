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
; Constant
;-------------------------------------------------------------------------------

LOAD_BUT .set 0x01	;load button
INC_BUT  .set 0x02  ;increment button
DEB_VAL  .set 0xFFFF  ;debouncing

;-------------------------------------------------------------------------------
; Init
;-------------------------------------------------------------------------------

;ports direction
    mov #0x00, P3DIR  ;input
    mov #0xFF, P2DIR  ;output
    mov #0xFC, P1DIR  ;buttons
;buttons interruptions
    bis #0x03, &P1IES  ;
    bis #0x03, &P1IE  ;enable interrupt
	bis.w #0x08, SR
;inicjalizacja
    mov #0x00, R4  ;counter init
    mov R4, P2OUT  ;output "init"
    jmp SLEEP

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

SLEEP:
	bis #CPUOFF|SCG1|SCG0|OSCOFF|GIE, SR ; LMP 4, EI  ;
	NOP
	bit #LOAD_BUT, R6	;interrupt report
	jz LOAD
	jmp MAIN

MAIN:
	mov #DEB_VAL, R5
	bit #LOAD_BUT, P1IN
	jz COUNT

COUNT:
	SETC
	DADC R4	;inc decimally
	mov R4, P2OUT  ;output

INTERRUPT:
    bic #CPUOFF|SCG1|SCG0|OSCOFF, 0(SP) ; wake up
    bic #LOAD_BUT|INC_BUT, P1IFG  ; allow interrupt
    mov P1IN, R6	;what happened
    RETI

LOAD:
	mov P3IN, R4
    mov R4, P2OUT
    bit #LOAD_BUT, P1IN	;infinite load (as long as you keep button pressed)
    jz LOAD
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
            
