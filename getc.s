; get keypress using the kernal & print the code


.autoimport	on              ; imports _cprintf, pushax
.importzp	sp
.forceimport	__STARTUP__ ; imports STARTUP, INIT, ONCE
.export		_main           ; expose mane to the C library
.segment	"RODATA"
_Text:                      ; PETSCII text to print
	.byte	$25,$30,$32,$58,$0D,$00       ; "%02x\n"

.segment    "DATA"

.segment	"CODE"
.proc	_main: near

loop:
    jsr _cgetc
    jsr pusha    ; push result on stack
    lda #<(_Text) ; low byte function argument
    ldx #>(_Text) ; high byte function argument
	jsr pushax
	ldy #$02       ; get result from back of stack
	lda (sp),y
	jsr pusha0     ; push result + 0x00 on front of stack
	ldy #$04       ; 4 bytes of function arguments
	jsr _cprintf
	jsr incsp1     ; rewind stack pointer
    jmp loop



.endproc
