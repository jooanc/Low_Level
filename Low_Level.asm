TITLE Designing low-level I/O procedures     (Low_Level.asm)

; Author: Joo An Choi
; Last Modified: 06/8/2020 10:52 PM
; Email address: jooanchoi@gmail.com
; Description:	This program implements ReadVal, WriteVal and the macros 
;				getString and displayString using Irvine's ReadString and WriteString

INCLUDE Irvine32.inc

; (insert constant definitions here)
ARRAYSIZE		EQU		10
MAXLENGTH		EQU		100
ASCIIPLUS		EQU		43
ASCIIMINUS		EQU		45
ASCIIZERO		EQU		48
ASCIININE		EQU		57

.data
programTitle	BYTE	"Designing low-level I/O procedures",13, 10, 0
authorCredit	BYTE	"Written by: Joo An Choi", 13, 10, 10, 0
instruction		BYTE	"Please provide 10 signed decimal integers.", 13, 10
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 13, 10
				BYTE	"After you have finished inputting the raw numbers I will display a list", 13, 10
				BYTE	"of the integers, their sum, and their average value.", 13, 10, 10, 0
ecMessage		BYTE	"Under construction: Working on numbering each line of user's input and display a running subtotal.", 13, 10, 0

prompt			BYTE	"Please enter a signed number: ", 0
errorPrompt		BYTE	"Please try again: ", 0
errorMessage	BYTE	"ERROR: You did not enter an signed number or your number was too big.", 10, 0

summaryMessage	BYTE	"You entered the following numbers: ", 13 , 10, 0
sumMessage		BYTE	"The sum of these numbers is: ", 0
averageMessage	BYTE	"The rounded average is: ", 0

farewellMessage	BYTE	"Thanks for playing!", 0

testMsg			BYTE	"test successful", 0
endTestMsg		BYTE	"end test success!", 0

stringVar		DWORD	?
otherStuff		QWORD	?
myVarArray		DWORD	10 DUP(0)
numVar			DWORD	?
subtotal		DWORD	?
temp			DWORD	?
negative		BYTE	"-",0
empty			BYTE	" ",0
comma			BYTE	", ", 0

; (insert variable definitions here)

.code
;------------------------------------------------

getString	MACRO	promptAddress, lengthOfVar, varAddress
	push	edx				;Save edx register
	push	ecx
	mov	edx, promptAddress
	call	WriteString
	mov ecx, lengthOfVar
	mov edx, varAddress
	call	ReadString		;stores OFFSET in edx
	pop ecx
	pop	edx					;Restore edx
ENDM
;------------------------------------------------

;------------------------------------------------
displayString	MACRO	stringAddress
	push edx
	mov edx, stringAddress
	call WriteString
	pop edx
ENDM
;------------------------------------------------

main PROC

	push OFFSET programTitle
	push OFFSET authorCredit
	push OFFSET instruction
	push OFFSET ecMessage
	call introduction

	push OFFSET subtotal
	push OFFSET myVarArray
	push OFFSET ARRAYSIZE
	push OFFSET prompt
	push OFFSET MAXLENGTH
	push OFFSET numVar
	push OFFSET errorPrompt
	push OFFSET errorMessage
	push OFFSET	ASCIININE
	push OFFSET ASCIIZERO
	push OFFSET ASCIIMINUS
	push OFFSET ASCIIPLUS
	push OFFSET stringVar
	call getUserInput

	push OFFSET comma
	push OFFSET temp
	push OFFSET stringVar
	push OFFSET	myVarArray
	push OFFSET summaryMessage
	call displayList

	push OFFSET temp
	push OFFSET stringVar
	push OFFSET	subtotal
	push OFFSET sumMessage
	call PrintSum

	push OFFSET empty
	push OFFSET negative
	push OFFSET temp
	push OFFSET stringVar
	push OFFSET	subtotal
	push OFFSET averageMessage
	call PrintAvg

	push OFFSET farewellMessage
	call farewell

; (insert executable instructions here)

	exit	; exit to operating system
main ENDP

;------------------------------------------------
introduction PROC
;Displays an introduction message, extra-credit efforts, and prompts.
;
;receives
;			[ebp+20] = reference to programTitle
;			[ebp+16] = reference to authorCredit
;			[ebp+12] = reference to instrution
;			[ebp+8]	 = reference to	ecMessage
;------------------------------------------------	
	push ebp					;keep track of old ebp value
	mov ebp, esp				;update ebp to top of stack
	displayString	[ebp+20]
	displayString	[ebp+16]
	displayString	[ebp+12]
	displayString	[ebp+8]
	pop ebp
	ret 

introduction ENDP

;------------------------------------------------
getUserInput PROC
;Takes 10 valid user inputs(32 bit signed integers_ and puts then inside a 10 element DWORD array.
;
;preconditions: The inputs must be 32 bit signed integers. The array must be 10 element DWORD array
;
;postconditions: Changes registers ecx. [All changes registers cleared when returning to main]
;
;receives
;			[ebp+68]	= references to subtotal
;			[ebp+64]	= references to Array
;			[ebp+60]	= references to ARRAYSIZE
;			[ebp+56]	= references to prompt
;			[ebp+52]	= reference to MAXLENGTH
;			[ebp+48]	= reference to numVar
;			[ebp+44]	= reference to error prompt.
;			[ebp+40]	= reference to error message.
;			[ebp+36]	ASCII code value for nine
;			[ebp+32]	ASCII code value for zero
;			[ebp+28]	ASCII code value for minus
;			[ebp+24]	ASCII code value for plus
;			[ebp+20]	 = reference to	stringVar
;------------------------------------------------
	push ebp
	push eax
	push ebx
	push ecx
	mov ebp, esp

	mov ecx, [ebp+60]
	
fillArrayLoop:	
	call readVal
	call fillArray
	loop fillArrayLoop

	pop ecx
	pop ebx
	pop eax
	pop ebp

	ret 48

getUserInput ENDP


;------------------------------------------------
readVal PROC
;Calls the get String Macro, then validates the string to be valid signed 32 bit integer.
;
;preconditions: The inputs must be 32 bit signed integers. 
;
;postconditions:
;
;receives:
;			[ebp+76]	= references to subtotal
;			[ebp+72]	= references to Array
;			[ebp+68]	= references to ARRAYSIZE
;			[ebp+64]	= references to prompt
;			[ebp+60]	= reference to MAXLENGTH
;			[ebp+56]	= reference to numVar
;			[ebp+52]	= reference to error prompt.
;			[ebp+48]	= reference to error message.
;			[ebp+44]	ASCII code value for nine
;			[ebp+40]	ASCII code value for zero
;			[ebp+36]	ASCII code value for minus
;			[ebp+32]	ASCII code value for plus
;			[ebp+28]	 = reference to	stringVar
;------------------------------------------------
	push ebp
	mov ebp, esp

	getString	[ebp+64], [ebp+60], [ebp+28]

	call validateUserInput

	pop ebp

	ret
readVal ENDP

validateUserInput	PROC
;Validates user's numeric input.
;
;preconditions: The inputs must be 32 bit signed integers.
;
;postconditions: Changes registers eax, ebx, ecx, edx, esi, edi, and ebp. [All changes registers cleared when returning to main]
;
;receives
;			[ebp+112]	= references to subtotal
;			[ebp+108]	= references to Array
;			[ebp+104]	= references to ARRAYSIZE
;			[ebp+100]	= references to prompt
;			[ebp+96]	= reference to MAXLENGTH
;			[ebp+92]	= reference to numVar
;			[ebp+88]	= reference to error prompt.
;			[ebp+84]	= reference to error message.
;			[ebp+80]	ASCII code value for nine
;			[ebp+76]	ASCII code value for zero
;			[ebp+72]	ASCII code value for minus
;			[ebp+68]	ASCII code value for plus
;			[ebp+64]	 = reference to	stringVar
;------------------------------------------------
	pushad
	mov ebp, esp
	
Beginning:
	mov ebx, 0
	mov ebp, esp
	mov edi, [ebp+92]			;@variable

	mov esi, [ebp+64]			;loads reference to entered string to esi
	lodsb

	cmp al, [ebp+68]			;if first char is "+"
	je plus

	cmp al, [ebp+72]			;if first char is "-"
	je minus		

NextChar:
	cmp al, [ebp+76]			;if first char is x > 0
	jge	ConfirmBelow

	jmp ErrorJump

plus:
	lodsb
	jmp	ConfirmBelow

minus:
	lodsb
	mov bl, 1

ConfirmBelow:
	cmp al, [ebp+76]			; x>0
	jge SkipError
	jmp ErrorJump				;to make sure ++ or -- are not accepted as results
SkipError:	
	cmp bl, 1
	jne Positive
	cmp al, [ebp+80]			;if first char is 0 <_ x <_ 9
	jle StoreCharNeg

Positive:
	cmp al, [ebp+80]			;if first char is 0 <_ x <_ 9
	jle StoreChar

	jmp ErrorJump

StoreChar:
	sub al, [ebp+76]
	movsx	ecx, al

	push eax
	push ebx
	push ecx

	mov eax, 0
	mov ebx, [edi]
	mov ecx, 10

MultiplyTen:	
	add eax, ebx
	jo ErrorJump
	loop MultiplyTen

	mov [edi], eax

	pop ecx
	pop ebx
	pop eax

	add [edi], ecx
	jo ErrorJump

	lodsb
	cmp al, 0
	je EndProcess

	jmp NextChar

StoreCharNeg:
	sub al, [ebp+76]
	movsx	ecx, al

	push eax
	push ebx
	push ecx

	mov eax, 0
	mov ebx, [edi]
	mov ecx, 10

MultiplyTen2:
	cmp ebx, 0
	jl AlreadyNegative
	sub eax, ebx
	jmp InitialRun

AlreadyNegative:
	add eax, ebx

InitialRun:
	jo ErrorJump
	loop MultiplyTen2

	mov [edi], eax

	pop ecx
	pop ebx
	pop eax

	sub [edi], ecx
	jo ErrorJump

	lodsb
	cmp al, 0
	je EndProcess
	mov bl, 1
	jmp NextChar

ErrorJump:

	mov eax, 0
	mov [edi], eax		;resets variable to 0

	displayString	[ebp+88]
	getString	[ebp+100], [ebp+96], [ebp+64]
	jmp Beginning

EndProcess:
	popad

	ret 

validateUserInput ENDP

;------------------------------------------------
fillArray PROC
;Fills the array
;
;receives
;			[ebp+88]	= references to subtotal
;			[ebp+84]	= references to Array
;			[ebp+80]	= references to ARRAYSIZE
;			[ebp+76]	= references to prompt
;			[ebp+72]	= reference to MAXLENGTH
;			[ebp+68]	= reference to numVar
;			[ebp+64]	= reference to error prompt.
;			[ebp+60]	= reference to error message.
;			[ebp+56]	ASCII code value for nine
;			[ebp+52]	ASCII code value for zero
;			[ebp+48]	ASCII code value for minus
;			[ebp+44]	ASCII code value for plus
;			[ebp+40]	 = reference to	stringVar
;------------------------------------------------
	push eax
	push ebx
	push ecx
	push ebp
	mov ebp, esp

	mov ebx, [ebp+68]
	mov eax, [ebx]
	mov ecx, [ebp+84]
	mov [ecx], eax
	add ecx, 4
	mov [ebp+84], ecx

	mov edx, [ebp+88]
	add [edx], eax	
	mov edx, 0
	mov [ebx], edx

	pop ebp
	pop ecx
	pop ebx
	pop eax
	ret
fillArray ENDP



;------------------------------------------------
NumToString PROC
;Converts Num to String
;
;preconditions: The inputs must be 32 bit signed integers. 
;
;postconditions: Changes registers eax, ebx, ecx, edx, edi, esi, and ebp. [All changes registers cleared when returning to main]
;receives
;	[ebp+48]	= reference to sum prompts
;	[ebp+52]	= reference to subtotal
;	[ebp+56]	= stringVar
;	[ebp+60]	= temp
;------------------------------------------------
	push eax
	push ebx
	push ecx
	push edx
	push edi
	push esi
	push ebp
	mov ebp, esp
	mov esi, 0

	mov ebx, [ebp+52]
	mov eax, [ebx]
	cmp eax, 0
	jl ifNegative

	jmp ifPositive

ifNegative:
	neg eax
	mov esi, 1
ifPositive:
	mov ecx, 0
	mov ebx, 10

StringOntoStack:
	cdq
	div ebx
	push edx	;push string bytes onto system stack
	inc ecx

	cmp eax, 0
	jne StringOntoStack

	mov edi, [ebp+56]

StackOntoVar:
	cmp esi, 1
	je negativeSign
	jmp noSign
negativeSign:
	mov al, 45
	stosb
	mov esi, 0
noSign:

	pop temp
	mov ebx, [ebp+60]
	mov eax, [ebx]

	add al, 48
	stosb
	loop StackOntoVar

	mov al, 0
	stosb

	pop ebp
	pop esi
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax

	ret

NumToString ENDP

;------------------------------------------------
PrintSum	PROC
;Takes the subtotal generated while filling array and then prints this value.
;
;preconditions: The 10 element DWORD array must be filled
;
;postconditions:
;
;receives
;	[ebp+8]		= reference to sum prompts
;	[ebp+12]	= reference to subtotal
;	[ebp+16]	= stringVar
;	[ebp+20]	= temp
;------------------------------------------------
	push ebp
	mov ebp, esp
	displayString [ebp+8]

	call WriteVal
	call Crlf
	pop ebp

	ret 16
PrintSum	ENDP

;------------------------------------------------
WriteVal	PROC
;Takes the integer stored in num var and converts to string form equivalent.
;
;preconditions: There must be a 32 bit int value in numVar
;
;postconditions:
;
;receives
;	[ebp+8]		= reference to sum prompts
;	[ebp+12]	= reference to subtotal
;	[ebp+16]	= stringVar
;	[ebp+20]	= temp
;------------------------------------------------
	push ebp
	mov ebp, esp

	call NumToString
	displayString [ebp+24]
	pop ebp
	ret 
WriteVal	ENDP

;------------------------------------------------
PrintAvg	PROC
;Takes the subtotal generated while filling array and then prints this value by fdivising the subtotal by 10.
;
;preconditions: The 10 element DWORD array must be filled
;
;postconditions:

;receives
;	[ebp+8]		= reference to sum prompts
;	[ebp+12]	= reference to subtotal
;	[ebp+16]	= stringVar
;	[ebp+20]	= temp
;------------------------------------------------
	push ebp
	mov ebp, esp
	displayString [ebp+8]

	mov ebx, [ebp+12]
	mov eax, [ebx]
	cmp eax, 0
	jl negativeNumber
	jmp positiveNumber
negativeNumber:
	neg eax
	mov esi, 1
positiveNumber:
	mov ebx, 10

	cdq
	div ebx
	mov ebx, [ebp+12]
	mov [ebx], eax

	cmp esi, 1
	je displayNegativeSign
	jmp result

displayNegativeSign:
	displayString [ebp+24]

result:
	call WriteVal
	call Crlf
	pop ebp


	ret 16
PrintAvg ENDP

;------------------------------------------------
displayList	PROC
;Displays the List
;
;receives
;	[ebp+8]		= reference to display prompts
;	[ebp+12]	= reference to array
;	[ebp+16]	= stringVar
;	[ebp+20]	= temp
;------------------------------------------------
	push ebp
	mov ebp, esp
	displayString [ebp+8]

	call WriteVal
	displayString[ebp+24]

	mov eax, 4
	mov ecx, 8
beginDisplayLoop:
	add [ebp+12], eax
	call WriteVal
	displayString[ebp+24]
	loop beginDisplayLoop

	add[ebp+12], eax
	call WriteVal
	call Crlf
	call Crlf

	pop ebp
	ret 20
displayList	ENDP

;------------------------------------------------	
farewell PROC
;Displays farewell prompt
;
;receives
;			[ebp+8]	 = reference to	farewellPrompt
;------------------------------------------------	

	call Crlf
	displayString [esp+8]
	ret 4
farewell ENDP


; (insert additional procedures here)

END main
