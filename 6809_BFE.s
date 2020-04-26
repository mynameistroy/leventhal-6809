;
;	Title:			Bit Field Extraction
;	Name:			BFE
;
;	Purpose:		Extract a field of bits from a 
;				16-bit word and return the field 
;				normalized to bit 0.
;
;			NOTE:	IF THE REQUESTED FIELD IS TOO LONG, 
;				THEN ONLY THE BITS THROUGH BIT 15 
;				WILL BE RETURNED.
;				FOR EXAMPLE, IF A 4 BIT FIELD IS 
;				REQUESTED STARTING AT BIT 15,
;				THEN ONLY 1 BIT (BIT 15) WILL BE RETURNED.
;
;	Entry:			TOP OF STACK
;				High byte of return address
;				Low  byte of return address
;				Lowest (starting) bit position 
;				in the field (0..15)
;				Width of field in bits (1..16)
;				High byte of data
;				Low  byte of data
;
;	Exit:			Register D = Field (normalized to bit 0)
;
;	Registers Used:		A,B,CC,U,X
;
;	Time:			85 cycles overhead plus 
;				(27 * lowest bit position) cycles
;
;	Size:			Program 67 bytes
;
BFE:
;	LDU	,S		; SAVE RETURN ADDRESS
;
;	EXIT WITH ZERO RESULT IF WIDTH OF FIELD IS ZERO
;
	CLRB			; MAKE LOW BYTE OF FIELD ZERO INITIALLY
	LDA	3,S		; GET FIELD WIDTH
	BEQ	EXITBF		; BRANCH (EXIT) IF FIELD WIDTH IS ZERO
				; NOTE: RESULT IN D IS ZERO
;
;	USE FIELD WIDTH TO OBTAIN EXTRACTION MASK FROM ARRAY
;	MASK CONSISTS OF A RIGHT-JUSTIFIED SEQUENCE OF 1 BITS
;	WITH LENGTH GIVEN BY THE FIELD WIDTH
;
	DECA			; SUBTRACT 1 FROM FIELD WIDTH TO FORM INDEX
	ANDA	#$0F		; BE SURE INDEX IS 0 TO 15
	ASLA			; MULTIPLY BY 2 SINCE MASKS ARE WORDLENGTH

;;; does not assemble PCR

;;;	LEAX	MSKARY,PCR	; GET BASE ADDRESS OF MASK ARRAY
	LDX	A,X		; GET MASK FROM ARRAY
;
;	SHIFT MASK LEFT LOGICALLY TO ALIGN IT WITH LOWEST BIT
;	POSITION IN FIELD
;
	LDA	2,S		; GET LOWEST BIT POSITION	
	ANDA	#$0F		; MAKE SURE VALUE IS BETWEEN 0 AND 15
	BEQ	GETFLD		; BRANCH WITHOUT SHIFTING IF LOWEST
				; BIT POSITION IS 0	

	STA	,S		; SAVE LOWEST BIT POSITION IN STACK TWICE
	STA	1,S		; TO COUNT SHIFTS OF MASK, RESULT
	TFR	X,D		; MOVE MASK TO REGISTER D FOR SHIFTING		
SHFTMS:
	ASLB			; SHIFT LOW BYTE OF MASK LEFT LOGICALLY
	ROLA			; SHIFT HIGH BYTE OF MASK LEFT
	DEC	,S		; CONTINUE UNTIL 1 BITS ALIGNED TO
	BNE	SHFTMS		;  FIELD'S LOWEST BIT POSITION
;
;	OBTAIN FIELD BY LOGICALLY ANDING SHIFTED MASK WITH VALUE
;
GETFLD:
	ANDB	5,S		; AND LOW BYTE VALUE WITH MASK 
	ANDA	4,S		; AND HIGH BYTE OF VALUE WITH MASK
;		
; NORMALIZE FIELD TO BIT 0 BY SHIFTING RIGHT LOGICALLY 
; FROM LOWEST BIT POSITION
;
	TST	1,S		; TEST LOWEST BIT POSITION
	BEQ	EXITBF		; BRANCH (EXIT) IF LOWEST POSITION IS 0
SHFTFL:
	LSRA			; SHIFT HIGH BYTE OF FIELD RIGHT LOGICALLY
	RORB			; SHIFT LOW BYTE OF FIELD RIGHT
	DEC	1,S		; CONTINUE UNTIL LOWEST BIT OF FIELD IS
	BNE	SHFTFL		; IN BIT POSITIQN 0
; 
;	REMOVE PARAMETERS FROM STACK AND EXIT
;
EXITBF:
	LEAS	6,S		; REMOVE PARAMETERS FROM STACK
	JMP	,U		; EXIT TO RETURN ADDRESS
;
;	ARRAY OF MASKS WITH 1 TO 15 ONE BITS RIGHT-JUSTIFIED
;
MSKARY:

	FDB	0000000000000001B
	FDB	0000000000000011B
	FDB	0000000000000111B
	FDB	0000000000001111B
	FDB	0000000000011111B
	FDB	0000000000111111B
	FDB	0000000001111111B
	FDB	0000000011111111B
	FDB	0000000111111111B
	FDB	0000001111111111B
	FDB	0000011111111111B
	FDB	0000111111111111B
	FDB	0001111111111111B
	FDB	0011111111111111B
	FDB	0111111111111111B
;
;	SAMPLE EXECUTION
;
SC4A:
	LDA	POS		; GET LOWEST BIT POSITION
	LDB	NBITS		; GET FIELD WIDTH IN BITS
	LDX	VAL		; GET DATA
	PSHS	A,B,X		; SAVE PARAMETERS IN STACK
	JSR	BFE		; EXTRACT BIT FIELD
				; RESULT FOR VAL=1234H, NBITS=4
				; POS=4 IS D = 0003H
	BRA	SC4A
;
; DATA
;
VAL	FDB	$1234		; DATA
NBITS	FDB	4		; FIELD WIDTH IN BITS
POS	FDB	4		; LOWEST BIT POSITION

	END

