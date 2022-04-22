#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here
         jmp     st1 
         db     1021 dup(0)
		 
		 CNT0 EQU 20H
CREG EQU 26H


;initialise 8255A
PORT1A EQU 00H 	;controlling the LCD
PORT1B EQU 02H 	;input to LCD
PORT1C EQU 04H 	;upper - row
		        ;lower - column
CREG1 EQU 06H


;8255B is interfaced with ADC

PORT2A EQU 10H 	;input to DI device
PORT2B EQU 12H 	;ADC
PORT2C EQU 14H 	;PC1 - SOC OF ADC
				;PC3 - ADDC of ADC (used for selecting the ;first & second input channel of ADC)
				;PC5 - EOC of ADC
CREG2 EQU 16H

;define temperature range
temp_range db -35,-34,-33,-32,-31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11
		   db -10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
		   db 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59
		   db 60,61,62,63,64,65

;define humidity range
humidity_range db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36
			   db 37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70
			   db 71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100

CURR_TEMP db ?
CURR_HUMIDITY db ?
;TEMP db ?
DAT2 DB 3 DUP(" ");
;T DB 30H,31H


;main program
          
st1:      cli 
MOV AX,08000H
MOV DS,AX
MOV SS,AX
MOV ES,AX
MOV SP,08FFEH

;initialize 8253 with control word
MOV AL,00010110B
OUT CREG,AL
MOV AL,5
OUT CNT0,AL

;initialize 8255A with control word
MOV AL,10000000B 
OUT CREG1,AL
CALL DELAY_2MS

;initialize 8255b with control word for connecting to ADC
MOV AL,10011010B 
OUT CREG2,AL
CALL DELAY_2MS

X1:
CALL FETCH_TEMP   		 ;fetch temperature
MOV AL, CS:CURR_TEMP  		 ;store current temperature in AL
CALL FUNC 		  		 ;display temperature to LCD
LEA SI,CS:temp_range 		 ;load offset of temperature range into SI
DEC SI
MOV CX,100 

CALL DELAY
CALL DELAY
CALL DELAY

AGAIN:
INC SI 					 ;increment offset of temperature range
CMP [SI],AL 			 ;compare current temperature with value at offset
LOOPNE AGAIN 			 ;loop if temperature is not equal to value at offset

SUB SI,OFFSET CS:temp_range ;finds how far SI is from TEMP_RANGE offset
LEA DI,CS:humidity_range 	 ;load offset of start of humidity range into DI
ADD DI,SI 				 ;finds the offset at which the current humidity should be
MOV BL,[DI] 			 ;moves the "should be" humidity into BL
CALL FETCH_HUMIDITY		 ;fetch humidity
MOV AL, CS:CURR_HUMIDITY	 ;store current humidity in AL
CALL FUNC				 ;display humidity to LCD
CMP BL, CS:CURR_HUMIDITY	 ;compare current humidity with "should be" humidity
JAE X2					 ;if humidity is greater than "should be" humidity, humidifier doesn't need to on
MOV AL,00001111B		 ;turn on PC7 of 8255A connection to humidifier circuit using Bit set-reset mode
OUT CREG1,AL			 ;ouput to control register and switch on the humidifier


;if humidity is lower, loop until humidifer increases humidity to "should be" humidity
LOOP1:
CALL DELAY_2MS
CALL FETCH_HUMIDITY		 ;fetch humidity in loop
CMP BL, CS:CURR_HUMIDITY	 ;compare in loop
JL LOOP1				 ;if humidity is lower, loop again

MOV AL,00001110B		 ;if not, turn off the PC7 of 8255A connection to humidifier circuit 
OUT CREG1,AL      		 ;ouput to control register and switch off the humidifier

X2:
CALL DELAY_2MS
JMP X1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PROCEDURE TO FETCH CURRENT TEMPERATURE
FETCH_TEMP PROC NEAR

PUSH SI
;MOV AL,20H
;OUT PORT2A,AL

MOV AL,06H	;GIVE ADC	
OUT CREG2,AL

MOV AL,00H	;GIVE ALE
OUT CREG2,AL

MOV AL,02H	;GIVE SOC
OUT CREG2,AL

MOV AL,01H   ;SET ALE
OUT CREG2,AL

MOV AL,03H   ;SET SOC
OUT CREG2,AL

MOV AL,02H	;GIVE SOC
OUT CREG2,AL	

MOV AL,00H	;GIVE ALE
OUT CREG2,AL

LOOP2:
IN AL,PORT2C
CALL DELAY_2MS
AND AL,20H    ;CHECK FOR EOC    
CMP AL,20H
JNZ LOOP2
CALL DELAY_2MS

MOV AL,10011010B ;INITIALIZING 8255(2)
OUT CREG2,AL
IN AL,PORT2A ;AL HAS THE CURRENT TEMPERATURE

LEA SI, CS:CURR_TEMP
MOV [SI],AL
POP SI
RET
FETCH_TEMP ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PROCEDURE TO GET THE CURRENT HUMIDITY

FETCH_HUMIDITY PROC NEAR

PUSH SI

MOV AL,07H	;GIVE ADC	
OUT CREG2,AL

MOV AL,00H	;GIVE ALE
OUT CREG2,AL

MOV AL,02H	;GIVE SOC
OUT CREG2,AL

MOV AL,01H   ;SET ALE
OUT CREG2,AL

MOV AL,03H   ;SET SOC
OUT CREG2,AL

MOV AL,02H	;GIVE SOC
OUT CREG2,AL	

MOV AL,00H	;GIVE ALE
OUT CREG2,AL

LOOP2_1:
IN AL,PORT2C
CALL DELAY_2MS
AND AL,20H    ;CHECK FOR EOC    
CMP AL,20H
JNZ LOOP2_1
CALL DELAY_2MS

MOV AL,10011010B ;INITIALIZING 8255(2)
OUT CREG2,AL
IN AL,PORT2A ;AL HAS THE CURRENT HUMIDITY

LEA SI, CS:CURR_HUMIDITY
MOV [SI],AL
POP SI
RET

FETCH_HUMIDITY ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNC PROC NEAR
PUSH AX
PUSH BX
MOV AL,38H
CALL COMNDWRT
CALL DELAY
CALL DELAY
CALL DELAY
MOV AL,0EH
CALL COMNDWRT

MOV AL, 01  ;CLEAR LCD
CALL COMNDWRT
CALL DELAY
CALL DELAY

POP AX
PUSH AX
LEA DI, CS:DAT2
MOV BX,100D
MOV DX,0
DIV BX
ADD AL,30H
CALL DATWRIT ;ISSUE IT TO LCD
CALL DELAY
CALL DELAY       
MOV AX,DX
MOV BX,10D 
MOV DX,0
DIV BX
ADD AL,30H
CALL DATWRIT
CALL DELAY
CALL DELAY
MOV AX,DX 
MOV DX,0
ADD AL,30H
CALL DATWRIT   
CALL DELAY
CALL DELAY
POP BX
POP AX

RET
FUNC ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

COMNDWRT PROC ;THIS PROCEDURE WRITES COMMANDS TO LCD
OUT PORT1B, AL  ;SEND THE CODE TO PORT B
MOV AL, 00000100B ;RS=0,R/W=0,E=1 FOR H-TO-L PULSE
OUT PORT1A, AL
NOP
NOP	
MOV AL, 00000000B ;RS=0,R/W=0,E=0 FOR H-TO-L PULSE
OUT PORT1A, AL
RET
COMNDWRT ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DATWRIT PROC NEAR
	PUSH DX  ;SAVE DX 
	MOV DX,PORT1B  ;DX=PORT B ADDRESS
	OUT DX, AL ;ISSUE THE CHAR TO LCD
	MOV AL, 00000101B ;RS=1, R/W=0, E=1 FOR H-TO-L PULSE
	MOV DX, PORT1A ;PORT A ADDRESS
	OUT DX, AL  ;MAKE ENABLE HIGH
	MOV AL, 00000001B ;RS=1,R/W=0 AND E=0 FOR H-TO-L PULSE
	OUT DX, AL
	POP DX
	RET
DATWRIT ENDP ;WRITING ON THE LCD ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DELAY_2MS PROC NEAR
MOV CX,100
HER: NOP
 LOOP HER
RET
DELAY_2MS ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;DELAY IN THE CIRCUIT HERE THE DELAY OF 20 MILLISECOND IS PRODUCED
DELAY PROC
	MOV CX, 1325 ;1325*15.085 USEC = 20 MSEC
	W1: 
		NOP
		NOP
		NOP
		NOP
		NOP
	LOOP W1
	RET
DELAY ENDP 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DELAY_2S PROC
	MOV CX, 33125D 
	W2: 
		NOP
		NOP
		NOP
		NOP
		NOP
	LOOP W2
		MOV CX, 33125D 
	W3: 
		NOP
		NOP
		NOP
		NOP
		NOP
	LOOP W3
		MOV CX, 33125D 
	W4: 
		NOP
		NOP
		NOP
		NOP
		NOP
	LOOP W4
		MOV CX, 33125D 
	W5: 
		NOP
		NOP
		NOP
		NOP
		NOP
	LOOP W5
	RET
DELAY_2S ENDP
