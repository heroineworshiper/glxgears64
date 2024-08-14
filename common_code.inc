; 3D bitmap graphics on a commodore 64
; Copyright (C) 2023 Adam Williams <broadcast at earthling dot net>
; 
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

; common routines



common_init:
; select the screen for new drawing
; set up drawing on BMP1
    lda #1
    sta current_screen
    lda #<ytablehigh_BMP1
    sta ytablemod + 1
    lda #>ytablehigh_BMP1
    sta ytablemod + 2
; set up drawing on BMP0
;    lda #0
;    sta current_screen
;    lda #<ytablehigh_BMP0
;    sta ytablemod + 1
;    lda #>ytablehigh_BMP0
;    sta ytablemod + 2

; border color
	lda	#5
	sta	$d020
	sta	$d021

    ldy	#187
	sty	$d011		;bitmap mode

	lda	$DD02
	ora	#3
	sta	$DD02		;CIA-2 I/O default value 		

	lda	$dd00		; set the VIC bank
	and	#%11111100
	ora	#%00000010  ; $4000
	sta	$dd00

	lda $d018       ; set color memory relative to VIC bank
	and	#%00001111
	ora	#%01110000  ; vic bank + $1c00
	sta	$d018

	lda	$d018       ; set bitmap memory relative to VIC bank
	and	#%11110000
	ora	#%00001000  ; vic bank + $2000
	sta	$d018	


; set color memory to white pen on dark blue paper (also clears sprite pointers) on screen 2
	ldx	#$00
	lda	#$16
loopcol:
	sta	BMP0_COLOR,x	
	sta	BMP0_COLOR+$100,x
	sta	BMP0_COLOR+$200,x
	sta	BMP0_COLOR+$300,x
	inx
	bne	loopcol

; set color memory to white pen on dark blue paper (also clears sprite pointers) on screen 1
	ldx	#$00
	lda	#$16
loopcol2:
    sta	BMP1_COLOR,x	
	sta	BMP1_COLOR+$100,x
	sta	BMP1_COLOR+$200,x
	sta	BMP1_COLOR+$300,x
	inx
	bne	loopcol2

        jsr clear_BMP0
        jsr clear_BMP1


; test point
;    jsr clear_part
;X1_ = 100
;Y1_ = 100
;    lda #>X1_   ; high byte
;    sta x1_hi
;    lda #<X1_   ; low byte
;    sta x1_lo
;    lda #Y1_
;    sta y1
;    jsr plot
;    jsr swap_screen
;stop:
;   jmp stop

; test line
;X1 = 0
;Y1 = 0
;X2 = 255
;Y2 = 100
;    lda #>X1
;    sta x1
;    lda #<X1
;    sta x1_lo
;    lda #Y1
;    sta y1
;    lda #>X2
;    sta x2
;    lda #<X2
;    sta x2_lo
;    lda #Y2
;    sta y2
;    jsr draw_line
;    rts


    lda #$00
    sta x1_hi
    sta x2_hi ;high bytes of x coordinates are 0 (x vertexes are 8 bit)        

; starting rotation angles
    lda #0
    sta rx                  
    lda #0
    sta ry
    rts





; 8 bit X only
draw_line:
; computes deltax, deltay, decides what routine to be used
    ;lda x1_hi
    ;cmp x2_hi
    ;bcc compute_delta_x2_x1
    ;bne compute_delta_x1_x2        ;high bytes unused
    lda x1_lo
    cmp x2_lo
    bcc compute_delta_x2_x1			;compares x1 and x2 

compute_delta_x1_x2:
    sec
    lda x1_lo
    sbc x2_lo
    sta delta_x+1
    ;lda x1_hi
    ;sbc x2_hi
    ;sta delta_x				;delta_x = x1-x2

    lda #$01
    sta x_n					    ;delta_x negative

    jmp skip_compute_delta_x2_x1

compute_delta_x2_x1:
    sec
    lda x2_lo
    sbc x1_lo
    sta delta_x+1
    ;lda x2_hi
    ;sbc x1_hi
    ;sta delta_x				;delta_x = x2-x1

    lda #$00
    sta x_n					;delta_x positive

skip_compute_delta_x2_x1:

    lda y1
    cmp y2
    bcc compute_delta_y2_y1			;compares y1 and y2

    sec
    lda y1
    sbc y2
    sta delta_y				;delta_y = y1 - y2

    lda #$01
    sta y_n					;delta_y negative					

    jmp skip_compute_delta_y2_y1

compute_delta_y2_y1:

    sec
    lda y2
    sbc y1
    sta delta_y				;delta_y = y2 - y1

    lda #$00
    sta y_n					;delta_y positive

skip_compute_delta_y2_y1:


    ;lda delta_x 
    ;bne jump_110				;if high byte delta_x <> 0 then delta_x > delta_y
                                            ;high bytes unused 
    lda delta_x+1
    cmp delta_y 
    bcc jump_170			        ;if delta_x+1 < delta_y use routine 170

jump_110:
	jsr line_110			        ;else use routine 110

	jmp skip_jump_170

jump_170:
    jsr line_170


skip_jump_170:	
	rts





; fast line 

line_110:
;based on v1.3 SLJ 7/2/94
    ;x is only 8 bit - for the cube program is enough 

    lda #$00
    sta xp 
    sta accumulator  ;zeroes accumulator for line drawing 

    lda     x2_lo 
    sta     limit

    lda     x_n 
    bne     dec_limit

    inc     limit 
    jmp     skip_dec_limit 

dec_limit:
    dec     limit 

skip_dec_limit:
    sec
    LDA	accumulator              
    SBC     delta_x+1 
    sta     accumulator

LOOPL:
    jsr     plot 

LOOPLremoved:
    lda     x_n 
    bne     dec_x                           ;checks for delta_x sign  

    INC     x1_lo	                        ;Step in x
    jmp     skip_dec_x 

dec_x:
    DEC     x1_lo 

skip_dec_x:
    clc
    lda     accumulator 
    ADC	delta_y	                        ;Add DY
    sta     accumulator 
    BCC     NOPE	                        ;Time to step in y?

    lda     y_n
    bne     dec_y

    INC	y1	                        ;Step in y

    jmp     skip_dec_y

dec_y:
    dec     y1 

skip_dec_y:
    SEC 
    LDA     accumulator 
    SBC	delta_x+1	                ;Reset counter
    sta     accumulator 

NOPE:
    lda     x1_lo
    cmp     limit 	                        ;At the endpoint yet?
    bne	LOOPL
    RTS


;fast line for dy > dx
line_170:
;based on v1.3 SLJ 7/2/94
    ;x is only 8 bit - for the cube program is enough 

    lda #$00
    sta xp 
    sta accumulator   ;zeroes accumulator for line drawing 

    lda     y2 
    sta     limit

    lda     y_n 
    bne     dec_limit2

    inc     limit 
    jmp     skip_dec_limit2 

dec_limit2:
    dec     limit 

skip_dec_limit2:
    sec
    LDA	accumulator              
    SBC     delta_y
    sta     accumulator

LOOPL2:
    jsr     plot 


LOOPL2removed:
    lda     y_n 
    bne     dec_y2                          ;checks for delta_x sign  

    INC     y1	                        ;Step in y
    jmp     skip_dec_y2 

dec_y2:
    DEC     y1 

skip_dec_y2:
    clc
    lda     accumulator 
    ADC	delta_x+1	                ;Add DX
    sta     accumulator 
    BCC     NOPE2	                        ;Time to step in x?

    lda     x_n
    bne     dec_x2

    INC	x1_lo	                        ;Step in x

    jmp     skip_dec_x2

dec_x2:
    dec     x1_lo 

skip_dec_x2:
    SEC 
    LDA     accumulator 
    SBC	delta_y 	                ;Reset counter
    sta     accumulator 

NOPE2:
    ;jsr     plot		                ;Plot the point
    lda     y1
    cmp     limit      	                ;At the endpoint yet?
    bne	LOOPL2
    RTS



; plot a point (codebase64.org)

plot:
; BMP0 = start of bitmap screen
; byteaddr = address of the byte where the point to plot lies
    ldy y1
    ldx x1_lo        ; X low byte  -> X


.ifdef USE_X16
; reset the lookup table after the last plot command
    lda #>xtablehigh
    sta xtablemod + 2	  ; self modifying code

    lda x1_hi            ; X high byte -> A
    beq skipadj       ; branch if high byte 0

; add high byte to the lookup table so the index can be only 8 bits
        lda #>(xtablehigh + $ff)		;added brackets, otherwise it won't work
        sta xtablemod + 2	  ; self modifying code
skipadj:
.endif ; USE_X16

; compute low byte of destination address from lookup tables
    lda ytablelow, y
    clc
    adc xtablelow, x
    sta byteaddr

; high byte of destination address comes from Y only
ytablemod:
    lda ytablehigh_BMP0,y

.ifdef USE_X16
xtablemod:
; xtablehigh is self modified for X > 255
    adc xtablehigh,x
.else
; add carry bit to high byte
    adc #00
.endif

    sta byteaddr + 1


; OR the pixel with the address
    ldy #$00
    lda (byteaddr),y
    ora bitable,x
    sta (byteaddr),y
    rts



; clear entire screen
clear_BMP1:
	ldy	#32
    lda	#<BMP1	; set starting address
	sta	modfull1 + 1
	lda	#>BMP1
	sta	modfull1 + 2	
    jmp loop_clear_full

clear_BMP0:
	ldy	#32
    lda	#<BMP0	; set starting address
	sta	modfull1 + 1
	lda	#>BMP0
	sta	modfull1 + 2	

loop_clear_full:
	ldx	#250
	lda	#$ff            ;filling value 
loop_clear_full2:
	dex
modfull1:
    sta	BMP0,x
    bne	loop_clear_full2
	    clc
	    lda	modfull1+1
	    adc	#250
	    sta	modfull1+1
	    lda	modfull1+2
	    adc	#00
	    sta	modfull1+2
	    dey
	    bne	loop_clear_full
	        rts

; clear the current drawing area
clear_part:
    lda current_screen 
    bne clear_part_BMP1 

clear_part_BMP0:
; current_screen == 0
; clear cols 0 - 255
        lda #$00
        ldx #0
; loop 256 times
clear_part_BMP0_loop:
        sta BMP0+0*320,x
        sta BMP0+1*320,x
        sta BMP0+2*320,x
        sta BMP0+3*320,x
        sta BMP0+4*320,x
        sta BMP0+5*320,x
        sta BMP0+6*320,x
        sta BMP0+7*320,x
        sta BMP0+8*320,x
        sta BMP0+9*320,x
        sta BMP0+10*320,x
        sta BMP0+11*320,x
        sta BMP0+12*320,x
        sta BMP0+13*320,x
        sta BMP0+14*320,x
        sta BMP0+15*320,x
        sta BMP0+16*320,x
        sta BMP0+17*320,x
        sta BMP0+18*320,x
        sta BMP0+19*320,x
        sta BMP0+20*320,x
        sta BMP0+21*320,x
        sta BMP0+22*320,x
        sta BMP0+23*320,x
        sta BMP0+24*320,x
        inx
        bne	clear_part_BMP0_loop
            rts




clear_part_BMP1:
; current_screen == 1
; clear cols 0 - 255
    lda #$00
    ldx #0
; loop 256 times
clear_part_BMP1_loop:
    sta BMP1+0*320,x
    sta BMP1+1*320,x
    sta BMP1+2*320,x
    sta BMP1+3*320,x
    sta BMP1+4*320,x
    sta BMP1+5*320,x
    sta BMP1+6*320,x
    sta BMP1+7*320,x
    sta BMP1+8*320,x
    sta BMP1+9*320,x
    sta BMP1+10*320,x
    sta BMP1+11*320,x
    sta BMP1+12*320,x
    sta BMP1+13*320,x
    sta BMP1+14*320,x
    sta BMP1+15*320,x
    sta BMP1+16*320,x
    sta BMP1+17*320,x
    sta BMP1+18*320,x
    sta BMP1+19*320,x
    sta BMP1+20*320,x
    sta BMP1+21*320,x
    sta BMP1+22*320,x
    sta BMP1+23*320,x
    sta BMP1+24*320,x
    inx
    bne	clear_part_BMP1_loop
        rts



swap_screen:
; wait for raster line >= 256
    lda $d011
    bpl swap_screen


    lda current_screen
    bne screen2_active

; current_screen == 0
; set up plot function
        lda #<ytablehigh_BMP1
        sta ytablemod + 1
        lda #>ytablehigh_BMP1
        sta ytablemod + 2

	    lda $d018
	    and	#%00001111  ; set color memory relative to VIC bank
	    ora	#%01110000  ; vic bank + $1c00
	    sta	$d018

        lda	$dd00		; set the VIC bank
	    and	#%11111100
	    ora	#%00000010  ; $4000
	    sta	$dd00


; toggle flag
        inc current_screen
        rts          

screen2_active:
; current_screen == 1
; set up plot function
    lda #<ytablehigh_BMP0
    sta ytablemod + 1
    lda #>ytablehigh_BMP0
    sta ytablemod + 2


	lda $d018           ; set color memory relative to VIC bank
	and	#%00001111
;	ora	#%01110000      ; vic bank + $1c00
	ora	#%00010000      ; only vic bank + $0400 works
	sta	$d018

	lda	$dd00		    ; set the VIC bank
	and	#%11111100
	ora	#%00000001      ; $8000
	sta	$dd00


; toggle flag
    dec current_screen
    rts






; product2_hi = (product2_hi, product2_lo) / 128
; do it by shifting left 1 bit & returning the high byte
divide_product2_128:
    lda product2_hi
    bpl divide_product2_128_    

; negative number
; get twos complement
        TWOS16 product2_hi, product2_lo

; shift left 1 bit
        asl product2_lo
        rol product2_hi

; get twos complement of high byte
        lda #$00
        sbc product2_hi
        sta product2_hi
        rts

divide_product2_128_:
; positive number
; shift left 1 bit
    asl product2_lo
    rol product2_hi
    rts


; product_hi = (product_hi, product_lo) / 128
; do it by shifting left 1 bit & returning the high byte
divide_product_128:
    lda product_hi
    bpl divide_product_128_   

; negative number
; get twos complement
        TWOS16 product_hi, product_lo

; shift left 1 bit
        asl product_lo
        rol product_hi

; get twos complement of high byte
        lda #$00
        sbc product_hi
        sta product_hi
        rts

divide_product_128_:
; positive number
; shift left 1 bit
    asl product_lo
    rol product_hi
    rts



; product_hi = (product_hi, product_lo) / 64
; do it by shifting left 2 bits & returning the high byte
divide_product_64:
    lda product_hi
    bpl divide_product_64_
; negative number
; get twos complement
        TWOS16 product_hi, product_lo

; shift left 2 bits
        asl product_lo
        rol product_hi
        asl product_lo
        rol product_hi

; get twos complement of high byte
        TWOS8 product_hi
        rts

divide_product_64_:
; shift left 2 bits
    asl product_lo
    rol product_hi
    asl product_lo
    rol product_hi
    rts 









; signed 8 bit multiply
multiply_ab8:
	lda	#$00
	sta	product_lo
    sta multiply_a_sign   ; multiply_a sign positive
    sta multiply_b_sign   ; multiply_b sign positive

	ldx	#8		;number of bits

    lda     multiply_a    ; check sign on A
    bpl     skip_multiply_a_sign
        TWOS8 multiply_a  ; take complement of multiply_a 
; multiply_a sign set to negative
        inc     multiply_a_sign 
skip_multiply_a_sign:

    lda     multiply_b
    bpl     skip_multiply_b_sign            ; check  sign on B
        TWOS8 multiply_b      ; take complement of multiply_b 
; multiply_b sign set to negative
        inc     multiply_b_sign 
skip_multiply_b_sign:       


; fast multiply
    lda #>square_low
    sta mod12+2
    lda #>square_high
    sta mod22+2

    clc
    lda multiply_a
    adc multiply_b
    bcc skip_inc
        inc mod12+2
        inc mod22+2
                
skip_inc:
    tax             

    sec
    lda multiply_a
    sbc multiply_b             
    bcs no_diff_fix

        sec
        lda multiply_b
        sbc multiply_a

no_diff_fix:    
    tay
    sec
mod12:
    lda square_low,x 
    sbc square_low,y
    sta product_lo

                
mod22:
    lda square_high, x
    sbc square_high, y
    sta product_hi



; product_hi is high byte, product_lo is low byte 
; sign of product evaluation

    lda multiply_a_sign
    eor multiply_b_sign         


;if product is positive, skip product complement
    beq skip_product_complement8 

; take 2 complement of product (16 bit)
        TWOS16 product_hi, product_lo


skip_product_complement8:
	rts
                





; adjust rotation with cursor keys
getc:
    jsr _cgetc   ; C library function
    cmp #$91     ; up
    bne getc2
        dec rx   ; decrease X rotation
        dec rx   ; decrease X rotation
        dec rx   ; decrease X rotation
        dec rx   ; decrease X rotation
        rts
getc2:
    cmp #$11     ; down
    bne getc3
        inc rx   ; increase X rotation
        inc rx   ; increase X rotation
        inc rx   ; increase X rotation
        inc rx   ; increase X rotation
        rts
getc3:
    cmp #$9d     ; left
    bne getc4
        inc ry   ; increase Y rotation
        inc ry   ; increase Y rotation
        inc ry   ; increase Y rotation
        inc ry   ; increase Y rotation
        rts
getc4:
    cmp #$1d     ; right
    bne getc5
        dec ry   ; decrease Y rotation
        dec ry   ; decrease Y rotation
        dec ry   ; decrease Y rotation
        dec ry   ; decrease Y rotation
        rts
getc5:
    rts

