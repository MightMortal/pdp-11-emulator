.SECTION .DATA
	FRAME_WIDTH: .WORD 0620
	FRAME_HEIGHT: .WORD 0454
	FRAME_WIDTH_BYTES: .WORD 0144
	FRAME_BUFFER_OFFSET: .WORD 0040000
	FRAME_BUFFER_SIZE: .WORD 0072460
	SYMBOL_IMAGE_SIZE: .WORD 020
	FONT_ADDRESS: .WORD 0154600
	KEYBOARD_TO_FONT_TABLE_ADDRESS: .WORD 0157634
	FLAG1: .WORD 0xDEAD
	FLAG2: .WORD 0xBEAF
# Global variables addresses:
# Carriage_x_pos: 		0001000
# Carriage_y_pos: 		0001002
# Line_length: 			0001004
# Line_buffer_pointer: 	0001006
# Line_buffer_start: 	0001010

.SECTION .CODE
.GLOBAL MAIN

# /-------------------------------------------------------\
# | MAIN ROM FUNCTION                                     |
# \-------------------------------------------------------/
MAIN:
	# Configure keyboard interrupt handler
	MOV KEYBOARD_PUSH_BUTTON_EVENT_HANDLER, (0176002)
	MOV 0000340, (0176004)
	
	# Configure echo console
	JSR R7, CLEAR_SCREEN_FUNCTION
ECHO_LOOP:
	WAIT
	BR ECHO_LOOP

	HALT

# /-------------------------------------------------------\
# | KEYBOARD PUSH BUTTON ECHO HANDLER                     |
# \-------------------------------------------------------/
KEYBOARD_PUSH_BUTTON_EVENT_HANDLER:
	BIT 0001000, (0176000)
	BNE KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_RENDER
	RTI

KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_RENDER:
	# Save registers R0-R2
	MOV R0, -(R6)
	MOV R1, -(R6)
	MOV R2, -(R6)

	# Enter pressed
	CMP 0001000, (0176000)
	BEQ KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_NEW_LINE
	CMP 0001001, (0176000)
	BEQ KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_BACKSPACE

	# Alloc arguments memory
	MOV (0001000), -(R6)
	MOV (0001002), -(R6)
	MOV 0000000, -(R6)
	# char_code: SP+0
	# y: SP+2
	# x: SP+4

	# Configure char_code argument
	# In-place code convertion
	MOV (0176000), 0(R6)
	BIC 0001000, 0(R6)
	JSR R7, KEYBOARD_TO_FONT_CONVERT_FUNCTION

	# Increment line length
	INC (0001004)
	
	# Move character to the line buffer
	MOV (0001006), R0
	MOV 0(R6), R0+
	MOV R0, (0001006)

	JSR R7, PRINT_SCREEN_CHAR_FUNCTION
	ADD 6, R6

	ADD 010, (0001000)
	CMP (0001000), (FRAME_WIDTH)
	BNE KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_END

	# Move carriage to next line
	MOV 0000000, (0001000)
	ADD 012, (0001002)
	CMP (0001002), (FRAME_HEIGHT)
	BLT KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_END
	JSR R7, CLEAR_SCREEN_FUNCTION
	BR KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_END

KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_NEW_LINE:
	MOV 0000000, (0001000)
	MOV 0000000, (0001004)
	MOV 0001010, (0001006)
	ADD 012, (0001002)

	# Print > symbol at start of the line
	JSR R7, PRINT_GREETING_SYMBOL_FUNCTION
	
	CMP (0001002), (FRAME_HEIGHT)
	BLT KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_END
	JSR R7, CLEAR_SCREEN_FUNCTION
	BR KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_END

KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_BACKSPACE:
	CMP 000, (0001004)
	BEQ KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_END


	# Increment line length
	DEC (0001004)

	ADD -010, (0001000)
	BPL KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_BACKSPACE1

	MOV (FRAME_WIDTH), R0
	ADD -010, R0
	MOV R0, (0001000)
	ADD -012, (0001002)

KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_BACKSPACE1:
	MOV (0001000), -(R6)
	MOV (0001002), -(R6)
	MOV 0000136, -(R6)
	JSR R7, PRINT_SCREEN_CHAR_FUNCTION
	ADD 6, R6

KEYBOARD_PUSH_BUTTON_EVENT_HANDLER_END:
	# Restore registers R0-R2
	MOV (R6)+, R2
	MOV (R6)+, R1
	MOV (R6)+, R0

	RTI

# /-------------------------------------------------------\
# | PRINT GREETING SYMBOL FUNCTION                        |
# \-------------------------------------------------------/
PRINT_GREETING_SYMBOL_FUNCTION:
	MOV (0001000), -(R6)
	MOV (0001002), -(R6)
	MOV 0000105, -(R6)
	JSR R7, PRINT_SCREEN_CHAR_FUNCTION
	ADD 6, R6
	ADD 010, (0001000)
	RST R7

# /-------------------------------------------------------\
# | CLEAR SCREEN FUNCTION                                 |
# \-------------------------------------------------------/
CLEAR_SCREEN_FUNCTION:
	MOV (FRAME_BUFFER_OFFSET), -(R6)
	MOV 0000000, -(R6)

CLEAR_SCREEN_FUNCTION_LOOP:
	CMP 0(R6), FRAME_BUFFER_SIZE
	BLT CLEAR_SCREEN_FUNCTION_END
	MOV 0000000, @2(R6)
	
	ADD 2, 2(R6)
	ADD 2, 0(R6)
	
	BR CLEAR_SCREEN_FUNCTION_LOOP

CLEAR_SCREEN_FUNCTION_END:
	ADD 4, R6
	MOV 0000000, (0001000)
	MOV 0000000, (0001002)
	MOV 0000000, (0001004)
	MOV 0001010, (0001006)

	JSR R7, PRINT_GREETING_SYMBOL_FUNCTION
	RST R7


# /-------------------------------------------------------\
# | CONVERT KEYBOARD CODE TO FONT CODE FUNCTION           |
# \-------------------------------------------------------/
KEYBOARD_TO_FONT_CONVERT_FUNCTION:
	# Operands: keycode SP+2
	# Result: fontcode SP+2
	BIT 0000100, 2(R6)
	BEQ KEYBOARD_TO_FONT_CONVERT_LOWER

	BIC 0177700, 2(R6)
	ASL 2(R6)
	ADD (KEYBOARD_TO_FONT_TABLE_ADDRESS), 2(R6)
	MOV @2(R6), 2(R6)
	SWAB 2(R6)
	BIC 0177400, 2(R6)
	RST R7

KEYBOARD_TO_FONT_CONVERT_LOWER:
	BIC 0177700, 2(R6)
	ASL 2(R6)
	ADD (KEYBOARD_TO_FONT_TABLE_ADDRESS), 2(R6)
	MOV @2(R6), 2(R6)
	BIC 0177400, 2(R6)
	RST R7

# /-------------------------------------------------------\
# | SCREEN SYMBOL BLINK FUNCTION                          |
# \-------------------------------------------------------/
SCREEN_SYMBOL_BLINK_FUNCTION:
	# Operands: x, y
	# Old R5 value: SP+0
	# y: SP+2
	# x: SP+4

	# Additional Variable
	# tmp: SP+0
	# vram_line_offset: SP+2

	# vram_line_offset
	MOV (FRAME_BUFFER_OFFSET), -(R6)
	# tmp
	MOV 0000000, -(R6)

	# Old R5 value: SP+4
	# y: SP+6
	# x: SP+8

	ASR 8(R6)
	ASR 8(R6)
	ADD 8(R6), 2(R6)

SCREEN_SYMBOL_BLINK_H_OFFSET_LOOP:
	CMP 0(R6), 6(R6)
	BEQ SCREEN_SYMBOL_BLINK_RENDER
	ADD (FRAME_WIDTH_BYTES), 2(R6)
	INC 0(R6)
	BR SCREEN_SYMBOL_BLINK_H_OFFSET_LOOP

SCREEN_SYMBOL_BLINK_RENDER:
	CLR 0(R6)

SCREEN_SYMBOL_BLINK_RENDER_LOOP:
	CMP 010, 0(R6)
	BEQ SCREN_SYMBOL_BLINK_END
	COM @2(R6)
	ADD (FRAME_WIDTH_BYTES), 2(R6)
	INC 0(R6)
	BR SCREEN_SYMBOL_BLINK_RENDER_LOOP

SCREN_SYMBOL_BLINK_END:
	ADD 4, R6
	RST R7


# /-------------------------------------------------------\
# | PRINT SCREEN CHARACTER FUNCTION                       |
# \-------------------------------------------------------/
PRINT_SCREEN_CHAR_FUNCTION:
	# Operands: x, y, char_code
	# Old R5 value: SP+0
	# char_code: SP+2
	# y: SP+4
	# x: SP+6

	# line_printed
	MOV 0000000, -(R6)
	# vram_line_offset
	MOV (FRAME_BUFFER_OFFSET), -(R6)
	# tmp
	MOV 0000000, -(R6)
	ASR 12(R6)
	ASR 12(R6)
	ADD 12(R6), 2(R6)
	
	# New stack state:
	# tmp: SP+0
	# vram_line_offset: SP+2
	# line_printed: SP+4
	# Old Reg value: SP+6
	# char_code: SP+8
	# y: SP+10
	# x: SP+12

PRINT_SCREEN_CHAR_H_OFFSET_LOOP:
	CMP 0(R6), 10(R6)
	BEQ PRINT_SCREEN_CHAR_LOAD_SYMBOL
	ADD (FRAME_WIDTH_BYTES), 2(R6)
	INC 0(R6)
	BR PRINT_SCREEN_CHAR_H_OFFSET_LOOP

PRINT_SCREEN_CHAR_LOAD_SYMBOL:
	MOV (FONT_ADDRESS), 0(R6)

PRINT_SCREEN_CHAR_LOAD_SYMBOL_LOOP:
	CMP 4(R6), 8(R6)
	BEQ PRINT_SCREEN_CHAR_RENDERING
	ADD (SYMBOL_IMAGE_SIZE), 0(R6)
	INC 4(R6)
	BR PRINT_SCREEN_CHAR_LOAD_SYMBOL_LOOP

PRINT_SCREEN_CHAR_RENDERING:
	CLR 4(R6)

PRINT_SCREEN_CHAR_RENDERING_LOOP:
	CMP 4(R6), 8
	BEQ PRINT_SCREEN_CHAR_END
	MOV @0(R6), @2(R6)
	ADD (FRAME_WIDTH_BYTES), 2(R6)
	INC 4(R6)
	INC 0(R6)
	INC 0(R6)
	BR PRINT_SCREEN_CHAR_RENDERING_LOOP

PRINT_SCREEN_CHAR_END:
	ADD 6, R6
	RST R7
