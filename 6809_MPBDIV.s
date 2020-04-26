	.macro	CLC
		ANDCC	#$FE
	.endm
	.macro	SEC
		ORCC	#1
	.endm

; 3F Multiple-precision binary division (MPBDIV)

;	Title:				Multiple-precision Binary Division
;	Name:				MPBDIV
;
;	Purpose:			Divide 2 arrays of binary bytes
;					Array1 := Array 1 / Array 2
;	Entry:
;					TOP OF STACK
;					High byte of return address
;					Low byte of return address
;					Length of arrays in bytes
;					High byte of divisor address
;					Low byte of divisor address
;					High byte of dividend address
;					Low byte of dividend address
;
;					The arrays are unsigned binary numbers 
;					with a maximum length of 255 bytes, 
;					ARRAY[0] is the least significant byte, and 
;					ARRAY[LENGTH-1] is the most significant byte.
;
;	Exit:
;

;					Array1 := Array1 / Array2 
;					Register X = Base address of remainder
;					If no errors then
;						Carry := 0
;					else
;						divide-by-zero error
;						Carry := 1
;						quotient := array 1 unchanged
;						remainder := 0
;	Registers Used:			All
;
;	Time:				Assuming there are length/2 1 bits in the
;					quotient then the time is approximately
;					(400 * length^2) + (580 * length) + 115 cycles
;
;	Size:			Program 137 bytes 
;				Data    514 bytes plus 2 stack bytes
;
MPBDIV:
;
; EXIT INDICATING NO ERROR IF LENGTH OF OPERANDS IS ZERO
;
	LDB	2,S 	; TEST LENGTH OF OPERANDS
	BEQ	GOODRT		; BRANCH (GOOD EXIT) IF LENGTH IS ZERO
;
;	SET UP HIGH DIVIDEND AND DIFFERENCE POINTERS
;	CLEAR HIGH DIVIDEND AND DIFFERENCE ARRAYS
;	ARRAYS 1 AND 2 ARE USED INTERCHANGEABLY FOR THESE TWO
;	PURPOSES.
;	THE POINTERS ARE SWITCHED WHENEVER A
;	TRIAL SUBTRACTION SUCCEEDS
;
	LDX	#HIDE1		; GET BASE ADDRESS OF ARRAY 1
	STX	HDEPTR		; DIVIDEND POINTER = ARRAY 1
	LDU	#HIDE2		; GET BASE ADDRESS OF ARRAY 2
	STU	DIFPTR		; DIVIDEND POINTER = ARRAY 2
	CLRA			; GET ZERO FOR CLEARING ARRAYS
CLRHI:
	STA	,X+		; CLEAR BYTE OF ARRAY 1
	STA	,U+		; CLEAR BYTE OF ARRAY 2
	DECB
	BNE	CLRHI		; CONTINUE THROUGH ALL BYTES
;
; CHECK WHETHER DIVISOR IS ZERO
; IF IT IS, EXIT INDICATING DIVIDE-BY-ZERO ERROR
;
	LDB	2,S		; GET LENGTH OF OPERANDS
	LDX	3,S		; GET BASE ADDRESS OF DIVISOR
CHKZRO:
	LDA	,X+		; EXAMINE BYTE OF DIVISOR
	BNE	INITDV		; BRANCH IF BYTE IS NOT ZERO
	DECB			; CONTINUE THROUGH ALL BYTES
	BNE	CHKZRO
	SEC			; ALL BYTES ARE ZERO INDICATE
				; DIVIDE-BY-ZERO ERROR
	BRA	DVEXIT		; EXIT
;
; SET COUNT TO NUMBER OF BITS IN THE OPERANDS
;	COUNT := (LENGTH * 8)
INITDV:
	LDB	2,S		; GET LENGTH OF OPERANDS IN BYTES
	LDA	#8		; MULTIPLY LENGTH TIMES 8
	MUL	
	PSHS	D		; SAVE BIT COUNT AT TOP OF STACK
;
; DIVIDE USING TRIAL SUBTRACTIONS
;
	CLC			; START QUOTIENT WITH U BIT
SHFTST:
				; POINT TO BASE ADDRESS OF DIVIDEND
				; GET LENGTH OF OPERANDS IN BYTES
;
; SHIFT QUOTIENT AND LOWER DIVIDEND LEFT ONE BIT
;
SHFTQU:
	ROL	,X+		; SHIFT BYTE OF QUOTIENT/DIVIDEND LEFT
	DECB			; CONTINUE THROUGH ALL BYTES
	BNE	SHFTQU
;
; SHIFT UPPER DIVIDEND LEFT WITH CARRY FROM LOWER DIVIDEND
;
	LDX	HDEPTR		; POINT TO BASE ADDRESS OF UPPER DIVIDEND
	LDB	4,S		; GET LENGTH OF OPERANDS IN BYTES
SHFTRM:
	ROL	,X+		; SHIFT BYTE OF UPPER DIVIDEND LEFT
	DECB			; CONTINUE THROUGH ALL BYTES
	BNE	SHFTRM
;
; TRIAL SUBTRACTION OF DIVISOR FROM DIVIDEND
; SAVE DIFFERENCE IN CASE IT IS NEEDED LATER
;
	LDU	DIFPTR		; POINT TO DIFFERENCE
	LDX	HDEPTR		; POINT TO UPPER DIVIDEND
	LDY	5,S		; POINT TO DIVISOR
	LDB	4,S		; GET LENGTH OF OPERANDS IN BYTES
	CLC			; CLEAR BORROW INITIALLY
SUBDVS:
	LDA	,X+		; GET BYTE OF UPPER DIVIDEND
	SBCA	,Y+		; SUBTRACT BYTE OF DIVISOR WITH BORROW
	STA	,U+		; SAVE DIFFERENCE
	DECB			; CONTINUE THROUGH ALL BYTES
	BNE	SUBDVS
;
; NEXT BIT OF QUOTIENT IS 1 IF SUBTRACTION HAS SUCCESSFUL,
; 0 IF IT HAS NOT
; THIS IS COMPLEMENT OF FINAL BORROW FROM SUBTRACTION
;
	BCC	RPLCDV		; BRANCH IF SUBTRACTION HAS SUCCESSFUL,
				; I.E., IT PRODUCED NO BORROW
	CLC			; OTHERWISE, TRIAL SUBTRACTION FAILED SO
				; MAKE NEXT BIT OF QUOTIENT ZERO
	BRA	SETUP
;
; TRIAL SUBTRACTION SUCCEEDED,
; SO REPLACE UPPER DIVIDEND WITH DIFFERENCE
; BY SWITCHING POINTERS
; SET NEXT BIT OF QUOTIENT TO 1
;
RPLCDV:
	LDX	HDEPTR		; GET HIGH DIVIDEND POINTER
	LDU	DIFPTR		; GET DIFFERENCE POINTER
	STU	HDEPTR		; NEW HIGH DIVIDEND = DIFFERENCE
	STX	DIFPTR		; USE OLD HIGH DIVIDEND FOR NEXT DIFFERENCE
	SEC			; SET NEXT BIT OF QUOTIENT TO 1
;
; DECREMENT BIT COUNT BY 1
;
SETUP:
	LDX	,S		; GET SHIFT COUNT
	LEAX	-1,S		; DECREMENT SHIFT COUNT BY 1
	STX	,S
	BNE	SHFTST		; CONTINUE UNLESS SHIFT COUNT EXHAUSTED
;
; SHIFT LAST CARRY INTO QUOTIENT IF NECESSARY
;
	LEAS	2,S		; REMOVE SHIFT CGUNTER FROM STACK
	BCC	GOODRT		; BRANCH IIF NO CARRY
	LDX	5,S		; POINT TO LOWER DIVIDEND/QUOTIENT
	LDB	2,S		; GET LENGTH OF OPERANDS IN BYTES
LASTSH:
;
	ROL	,X+		; SHIFT BYTE OF QUOTIENT
	DECB			; CONTINUE THROUGH ALL BYTES
	BNE	LASTSH
;
; CLEAR CARRY TO INDICATE NO ERRORS
;
GOODRT:
	CLC			; CLEAR CARRY - NO DIVIDE-BY-ZERO ERROR
;
; REMOVE PARAMETERS FROM STACK AND EXIT
;
DVEXIT:
	LDX	HDEPTR		; GET BASE ADDRESS OF REMAINDER
	LDU	,S		; SAVE RETURN ADDRESS
	LEAS	7,S		; REMOVE PARAMETERS FROM STACK
	JMP	,U		; EXIT TO RETURN ADDRESS
;
; DATA
;
HDEPTR:	RMB	2		; POINTER TO HIGH DIVIDEND
DIFPTR:	RMB	2		; POINTER TO DIFFERENCE BETWEEN HIGH
				; DIVIDEND AND DIVISOR
HIDE1:	RMB	255		; HIGH DIVIDEND BUFFER 1
HIDE2:	RMB	255		; HIGH DIVIDEND BUFFER 2
;
;
; SAMPLE EXECUTION
;
;
SC3F:	
	LDX	AY1ADR		; GET DIVIDEND	
	LDY	AY2ADR		; GET DIVISOR	
	LDA	#SZAYS		; LENGTH OF ARRAYS IN BYTES	
	PSHS	A,X,Y		; SAVE PARAMETERS IN STACK 	
	JSR	MPBDIV		; MULTIPLE-PRECISION BINARY DIVISION
	BRA	SC3F
				; RESULT OF 14B60404H / 1234H = 12345H

SZAYS	EQU	7		; LENGTH OF ARRAYS IN BYTES
AY1ADR	FDB	AY1		; BASE ADDRESS OF ARRAY 1 (DIVIDEND)
AY2ADR	FDB	AY2		; BASE ADDRESS OF ARRAY 2 (DIVISOR)
AY1:	FCB	$04,$04,$B6,$14,0,0,0,0
AY2:	FCB	$34,$12,0,0,0,0,0,0
	END