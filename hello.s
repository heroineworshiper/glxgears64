.autoimport	on              ; imports _cprintf, pushax
.forceimport	__STARTUP__ ; imports STARTUP, INIT, ONCE
.export		_main           ; expose mane to the C library
.segment	"RODATA"
_Text:                      ; PETSCII text to print
	.byte	$C8,$45,$4C,$4C,$4F,$20,$57,$4F,$52,$4C,$44,$21,$00


.segment	"CODE"
.proc	_main: near
    lda     #<(_Text) ; low byte function argument
    ldx     #>(_Text) ; high byte function argument
    jsr _puts         ; unformatted print
;    jsr     pushax ; put function arguments on stack
;    ldy     #$02   ; size of function arguments (2 bytes)
;    jsr     _cprintf ; C library function
.endproc
