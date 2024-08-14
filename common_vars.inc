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
; orthoganol mode
ORTHOGANOL := 1

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



current_screen := $20       ; flag for double-buffering 
x1_hi := $21
x1_lo := $22
y1 := $23
x2_hi := $24
x2_lo := $25
y2 := $26
byteaddr := $27
delta_x := $28 ; 2 bytes
delta_y := $2a
x_n := $2b
y_n := $2c

accumulator := $2d
limit := $2e
xp := $30
rx := $32
ry := $33
c_x := $34   ; cos for the X rotation
s_x := $35   ; sin for the X rotation
c_y := $36   ; cos for the Y rotation
s_y := $37   ; sin for the Y rotation
current_point := $38
current_point2 := $39
draw_count := $3a
product2_hi := $3b ; temporary multiply result
product2_lo := $3c
temp_y := $3d
temp_x := $3e
temp_z := $3f
proj_coef := $40  ; projection coefficient based on Z
multiply_a_sign := $41
multiply_b_sign := $42
product_hi := $43        ; high byte of multiply result
product_lo := $44        ; low byte of multiply result                  	
multiply_a := $45        ; input argument A
multiply_b := product_hi         ; input argument B.  Same address as result



