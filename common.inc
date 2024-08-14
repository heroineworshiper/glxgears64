
; printer device number
PRINTER = 4
PORT_REG := $0001
; port register values
KERNAL_IN := $36
KERNAL_OUT := $30

; macros
.macro SET_LITERAL8 address, value
    lda #<value
    sta address
.endmacro

.macro SET_LITERAL16 address, value
    lda #<value
    sta address
    lda #>value
    sta address + 1
.endmacro

.macro COPY_REG16 dst, src
    lda src
    sta dst
    lda src + 1
    sta dst + 1
.endmacro

.macro COPY_REG8 dst, src
    lda src
    sta dst
.endmacro

; dst = src + reg
.macro ADD_REG16 dst, src, reg
    clc
    lda src
    adc reg
    sta dst
    lda src + 1
    adc reg + 1
    sta dst + 1
.endmacro

; dst = literal + src
.macro ADD_LITERAL16 dst, src, literal
    clc
    lda #<literal ; low
    adc src
    sta dst
    lda #>literal ; high
    adc src + 1
    sta dst + 1
.endmacro

; dst = dst + 1
.macro INC16 dst
    inc dst
    bne :+ ; jump over inc
        inc dst + 1
: ; the jmp destination
.endmacro


; dst = literal + src
.macro ADD_LITERAL dst, src, literal
    clc
    lda #literal ; low
    adc src
    sta dst
.endmacro

; dst = src - literal
.macro SUB_LITERAL16 dst, src, literal
    sec
    lda src
    sbc #<literal ; low
    sta dst
    lda src + 1
    sbc #>literal ; high
    sta dst + 1
.endmacro

; dst = src - literal
.macro SUB_LITERAL dst, src, literal
    sec
    lda src
    sbc #literal ; low
    sta dst
.endmacro


; branch if address content >= literal
.macro BRANCH_GREATEREQUAL16 address, literal, where
    sec
    lda address
    sbc #<literal ; low
    lda address + 1
    sbc #>literal ; high
    bcs where
.endmacro

; branch if address content >= reg
.macro BRANCH_GREATEREQUAL16_REG address, reg, where
    sec
    lda address
    sbc reg ; low
    lda address + 1
    sbc reg + 1 ; high
    bcs where
.endmacro

.macro BRANCH_GREATEREQUAL address, literal, where
    sec
    lda address
    sbc #literal ; low
    bcs where
.endmacro

; branch if address content < literal
.macro BRANCH_LESS16 address, literal, where
    sec
    lda address
    sbc #<literal ; low
    lda address + 1
    sbc #>literal ; high
    bcc where
.endmacro

.macro BRANCH_LESS address, literal, where
    sec
    lda address
    sbc #literal ; low
    bcc where
.endmacro

.macro PRINT_TEXT string
    SET_LITERAL16 printmod + 1, string ; self modifying code
    jsr print
.endmacro

.macro PRINT_HEX16 address
    ldy address + 1
    jsr print_hex8
    ldy address
    jsr print_hex8
    lda #' '
    jsr CIOUT
.endmacro

.macro PRINT_HEX8 address
    ldy address
    jsr print_hex8
    lda #' '
    jsr CIOUT
.endmacro

.macro INIT_DEBUG
; open the printer page 338
    lda #7 ; logical number
    ldx #PRINTER ; device number
    ldy #7 ; secondary address
    jsr SETLFS

    jsr OPEN
.endmacro

.macro SELECT_PRINTER
; direct CIOUT to the printer
    lda #PRINTER
    jsr LISTEN
.endmacro

.macro SELECT_DATA
    lda #WORLD_DRIVE ; read from the data channel
    jsr TALK
    lda #(DATA | $60) ; secondary address needs to be ored with 0x60
    jsr TKSA
.endmacro


.macro SELECT_CONTROL
    lda #WORLD_DRIVE ; write to the command channel
    jsr LISTEN
    lda #(CONTROL | $60) ; secondary address needs to be ored with 0x60
    jsr SECOND
.endmacro


;set clock & data line high (inverted)
.macro CLKDATHI
	lda d2pra
	and #($ff - CLK_OUT - DAT_OUT)
	sta d2pra
.endmacro

;set clock line high (inverted)
.macro CLKHI
	lda d2pra
	and #($ff-CLK_OUT)
	sta d2pra
.endmacro

;set clock line low  (inverted)
.macro CLKLO
	lda d2pra
	ora #CLK_OUT
	sta d2pra
.endmacro

;set data line high (inverted)
.macro DATHI
	lda d2pra
	and #($ff-DAT_OUT)
	sta d2pra
.endmacro

;set data line low (inverted)
.macro DATLO
	lda d2pra
	ora #DAT_OUT
	sta d2pra
.endmacro

;set ATN line high (inverted)
.macro ATNHI
	lda d2pra
	and #($ff-ATN_OUT)
	sta d2pra
.endmacro

;set ATN line low (inverted)
.macro ATNLO
	lda d2pra
	ora #ATN_OUT
	sta d2pra
.endmacro


; setup timer for profiling
.macro INIT_PROFILER
    lda #$ff   ; reset CIA 2 timer A
    sta d2t1h
    sta d2t2l  ; reset CIA 2 timer B
    lda #$11
    sta d2cra  ; start timer A
    lda #$51
    sta d2crb  ; run timer B off of timer A
.endmacro

.macro GET_TIME dst
    lda #$ff
    sbc d2t1h ; get CIA 2 timer A
    sta dst
    lda #$ff
    sbc d2t2l ; get CIA 2 timer B
    sta dst + 1
    lda #$ff ; reset the clock
    sta d2t1h
    sta d2t2l
    lda #$11
    sta d2cra
    lda #$51
    sta d2crb
.endmacro
