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

; interactive rotation with cursor keys
INTERACTIVE = 1

; use 16 bit X
;USE_X16 = 1


.autoimport	on              ; imports C library functions
.forceimport	__STARTUP__ ; imports STARTUP, INIT, ONCE
.export		_main           ; expose mane to the C library
.include        "zeropage.inc"

; macros
BMP0 = $6000   ; starting address of bitmaps
;BMP1 = $2000
BMP1 = $a000
BMP0_COLOR = $5c00 ; starting address of color
;BMP1_COLOR = $0400
BMP1_COLOR = $8400


.macro SET_LITERAL16 address, value
    lda #<value
    sta address
    lda #>value
    sta address + 1
.endmacro

; twos complement of 16 bit register
.macro TWOS16 hi, lo
    sec 
    lda #$00
    sbc lo
    sta lo
    lda #$00
    sbc hi
    sta hi                
.endmacro

; twos complement of 8 bit register
.macro TWOS8 reg
    sec 
    lda #$00
    sbc reg
    sta reg
.endmacro

; copy using acumulator as a temporary
.macro COPY_REG16 srchi, srclo, dsthi, dstlo
    lda srchi
    sta dsthi
    lda srclo
    sta dstlo
.endmacro

; dst = a - b
.macro SUB_REG16 a_hi, a_lo, b_hi, b_lo, dst_hi, dst_lo
    sec
    lda a_lo                ; subtract low bytes
    sbc b_lo
    sta dst_lo              ; result low -> prod + 1
    lda a_hi                ; subtract high bytes
    sbc b_hi
    sta dst_hi              ; result high -> prod
.endmacro

; dst = a + b
.macro ADD_REG16 a_hi, a_lo, b_hi, b_lo, dst_hi, dst_lo
    clc
    lda a_lo
    adc b_lo
    sta dst_lo
    lda a_hi
    adc b_hi
    sta dst_hi
.endmacro


; multiply register * accumulator & store the result in product_hi, product_lo
.macro MULTIPLY_REGxA reg
    sta multiply_b
    lda reg
    sta multiply_a
    jsr multiply_ab8
.endmacro

; global variables
.segment	"DATA"


; zero page aliases
byteaddr := tmp1		; 2 bytes

current_screen:   .res    1       ; flag for double-buffering 
x1_hi:		      .res    1
x1_lo:		      .res    1
y1:			      .res    1
x2_hi:		      .res    1
x2_lo:		      .res    1
y2:			      .res    1
delta_x:	      .res    2
delta_y:	      .res    1
x_n:		      .res    1
y_n:		      .res    1

accumulator:     .res	1
limit:           .res	1
xp:		         .res	2
rx:              .res	1
ry:              .res	1
c_x:             .res 1   ; cos for the X rotation
s_x:             .res 1   ; sin for the X rotation
c_y:             .res 1   ; cos for the Y rotation
s_y:             .res 1   ; sin for the Y rotation
current_point:   .res	1
current_point2:  .res	1
draw_count:      .res	1
product2_hi:     .res	1 ; temporary multiply result
product2_lo:     .res	1
temp_y:          .res	1
temp_x:          .res	1
temp_z:          .res	1
proj_coef:       .res   1  ; projection coefficient based on Z
multiply_a_sign: .res	1
multiply_b_sign: .res	1
product_hi:      .res	1        ; high byte of multiply result
product_lo:      .res	1        ; low byte of multiply result                  	
multiply_a:      .res	1        ; input argument A
multiply_b := product_hi         ; input argument B.  Same address as result



