
print:
    ldx #$00          ; initialize X register for indexing
printmod:
    lda $ffff,x       ; load the character from the message
    beq print2        ; if character is zero, we are done
        jsr CIOUT     ; call CIOUT routine to send the character to the serial port
        inx           ; increment X register
        jmp printmod  ; repeat the loop
print2:
    rts

; print the value of Y.  Overwrites A, X
hex_table:
    .byte "0123456789abcdef"
print_hex8:
    tya
    and #$f0
    clc
    ror A
    ror A
    ror A
    ror A
    tax
    lda hex_table,x
    jsr CIOUT
    tya
    and #$0f
    tax
    lda hex_table,x
    jsr CIOUT
    rts

