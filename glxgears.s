; 3D bitmap graphics on a commodore 64
; Copyright (C) 2023-2024 Adam Williams <broadcast at earthling dot net>
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


; compile with make glxgears


.include "common_vars.inc"


.segment	"DATA"

; draw 2 sides
;DOUBLE_SIDED = 1

MAX_COORDS = 200

GEAR1_W = 10
GEAR2_W = 5
GEAR3_W = 20

; total coordinates to draw
total_coords: .res 1
; Z rotation of gears
rz:           .res	1
temp_rz:      .res  1
gear_z1:      .res  1
gear_z2:      .res  1


; range of points to draw
start_point: .res 1
end_point:   .res 1

; starting coordinates in two's complement form
x_coords:   .res MAX_COORDS
y_coords:   .res MAX_COORDS 
z_coords:   .res MAX_COORDS

; rotated coordinates
xd_coords:  .res MAX_COORDS
yd_coords:  .res MAX_COORDS
zd_coords:  .res MAX_COORDS

; 2D coordinates
vex:        .res MAX_COORDS
vey:        .res MAX_COORDS                      

.segment	"RODATA"


.include "tables.inc"
.include "gears.inc"

.segment	"CODE"
.proc	_main: near

; simplest way to create a memory hole for the bitmaps
;    jmp mane
;.res $7700
;mane:


    jsr common_init


.macro PROCEDURAL_GEAR total, sin_r1, cos_r1, sin_r2, cos_r2, angles, width
    lda #total      ; must be a multiple of 4
    sta total_coords

.ifdef DOUBLE_SIDED
; -width -> z1
    lda #00
    sec
    sbc #width
    sta gear_z1
; width -> z2
    lda #width
    sta gear_z2
.else
    lda #00
    sta gear_z1
    sta gear_z2
.endif


; modify code
    SET_LITERAL16 gear_mod1 + 1, sin_r1
    SET_LITERAL16 gear_mod2 + 1, cos_r1
    SET_LITERAL16 gear_mod3 + 1, sin_r2
    SET_LITERAL16 gear_mod4 + 1, cos_r2
    SET_LITERAL16 gear_mod5 + 1, sin_r2
    SET_LITERAL16 gear_mod6 + 1, cos_r2
    SET_LITERAL16 gear_mod7 + 1, sin_r1
    SET_LITERAL16 gear_mod8 + 1, cos_r1
    SET_LITERAL16 gear_mod9 + 1, angles
    SET_LITERAL16 gear_mod10 + 1, angles
    SET_LITERAL16 gear_mod11 + 1, angles
    SET_LITERAL16 gear_mod12 + 1, angles
    jsr procedural_gear
    jsr do_rotate
.endmacro


.macro PROCEDURAL_SHAFT total, sin_r, cos_r, angles, width
    lda #total
    sta total_coords
.ifdef DOUBLE_SIDED
; -width -> z1
    lda #00
    sec
    sbc #width
    sta gear_z1
; width -> z2
    lda #width
    sta gear_z2
.else
    lda #00
    sta gear_z1
    sta gear_z2
.endif
; modify code
    SET_LITERAL16 shaft_mod1 + 1, angles
    SET_LITERAL16 shaft_mod2 + 1, sin_r
    SET_LITERAL16 shaft_mod3 + 1, cos_r
    jsr procedural_shaft
    jsr do_rotate
.endmacro

mane_loop:
; clear the screen
    jsr clear_part
; draw gear1
    PROCEDURAL_GEAR GEAR1_N, gear1_sin_r1, gear1_cos_r1, gear1_sin_r2, gear1_cos_r2, gear1_angles, GEAR1_W
    PROCEDURAL_SHAFT SHAFT1_N, shaft1_sin_r, shaft1_cos_r, shaft1_angles, GEAR1_W
; reverse rotation & double speed
    lda rz
    sta temp_rz
    lda #00
    sec
    sbc rz
    sta rz
    asl rz
; phase offset
    lda #11
    clc
    adc rz
    sta rz
; draw gear2
    PROCEDURAL_GEAR GEAR2_N, gear2_sin_r1, gear2_cos_r1, gear2_sin_r2, gear2_cos_r2, gear2_angles, GEAR2_W
    PROCEDURAL_SHAFT SHAFT2_N, shaft2_sin_r, shaft2_cos_r, shaft2_angles, GEAR2_W
; phase offset
    lda rz
    sec
    sbc #11
    sta rz
; draw gear3
    PROCEDURAL_GEAR GEAR3_N, gear3_sin_r1, gear3_cos_r1, gear3_sin_r2, gear3_cos_r2, gear3_angles, GEAR3_W
    PROCEDURAL_SHAFT SHAFT3_N, shaft3_sin_r, shaft3_cos_r, shaft3_angles, GEAR3_W
; restore rotation
    lda temp_rz
    sta rz
    jsr swap_screen

; user rotation
.ifdef INTERACTIVE
;    jsr getc
; read the keyboard buffer
    jsr $ffe4
    beq flush_keypress
        jsr getin

flush_keypress:
; empty the buffer
;    jsr $ffe4
;    bne flush_keypress

; auto rotate
    inc rz
;    inc ry
;    inc rx

.else

; automatic XY rotation
    inc rx
    inc ry
    inc rx
    inc ry
    inc rx
    inc ry
    inc rx
    inc ry
    inc rz
.endif

; repeat
    jmp mane_loop


;ROTATE_STEP = 2
ROTATE_STEP = 8
; handle a buffered keypress
getin:
    cmp #$91     ; up
    bne getin2
        sec
        lda rx
        sbc #ROTATE_STEP
        sta rx
        rts
getin2:
    cmp #$11     ; down
    bne getin3
        clc
        lda rx
        adc #ROTATE_STEP
        sta rx
        rts
getin3:
    cmp #$9d     ; left
    bne getin4
        clc
        lda ry
        adc #ROTATE_STEP
        sta ry
        rts
getin4:
    cmp #$1d     ; right
    bne getin5
        sec
        lda ry
        sbc #ROTATE_STEP
        sta ry
        rts
getin5:
    rts
    

procedural_gear:
; convert polar to XYZ with Z rotation
    ldy #0                  ; the current point
gear_loop:
gear_mod9:
    lda gear1_angles, y     ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
gear_mod1:
    lda gear1_sin_r1, x     ; y = R1 * sin(angle)
    sta y_coords, y
gear_mod2:
    lda gear1_cos_r1, x     ; x = R1 * cos(angle)
    sta x_coords, y
    lda gear_z1
    sta z_coords, y
    iny

gear_mod10:
    lda gear1_angles, y     ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
gear_mod3:
    lda gear1_sin_r2, x     ; y = R2 * sin(angle)
    sta y_coords, y
gear_mod4:
    lda gear1_cos_r2, x     ; x = R2 * cos(angle)
    sta x_coords, y
    lda gear_z1
    sta z_coords, y
    iny

gear_mod11:
    lda gear1_angles, y     ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
gear_mod5:
    lda gear1_sin_r2, x ; y = R2 * sin(angle)
    sta y_coords, y
gear_mod6:
    lda gear1_cos_r2, x ; x = R2 * cos(angle)
    sta x_coords, y
    lda gear_z1
    sta z_coords, y
    iny

gear_mod12:
    lda gear1_angles, y     ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
gear_mod7:
    lda gear1_sin_r1, x ; y = R1 * sin(angle)
    sta y_coords, y
gear_mod8:
    lda gear1_cos_r1, x ; x = R1 * cos(angle)
    sta x_coords, y
    lda gear_z1
    sta z_coords, y
    iny

    cpy total_coords
        bne gear_loop

; copy first coordinate with Z shifted to start the back side
    lda x_coords
    sta x_coords,y
    lda y_coords
    sta y_coords,y
    lda gear_z2
    sta z_coords,y
    inc total_coords
; end procedural_gear
    rts



procedural_shaft:
; convert polar to XYZ with Z rotation
    ldy #0                  ; the current point
shaft_loop:
shaft_mod1:
    lda shaft1_angles, y    ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
shaft_mod2:
    lda shaft1_sin_r, x    ; y = R1 * sin(angle)
    sta y_coords, y
shaft_mod3:
    lda shaft1_cos_r, x     ; x = R1 * cos(angle)
    sta x_coords, y
    lda gear_z1
    sta z_coords, y
    iny
    cpy total_coords
        bne shaft_loop

; copy first coordinate with Z shifted to start the back side
    lda x_coords
    sta x_coords,y
    lda y_coords
    sta y_coords,y
    lda gear_z2
    sta z_coords,y
    inc total_coords
; end procedural_shaft
    rts

do_rotate:
; rotate all the coordinates about XY
; look up X rotation
    ldx rx
    lda cos_table, x
    sta c_x

    lda sin_table, x 
    sta s_x
; look up Y rotation
    ldx ry
    lda cos_table, x
    sta c_y

    lda sin_table, x 
    sta s_y


    lda #0                  ; the current point
    sta current_point 
rotate_loop:
; rotation about x axis 
; compute yd(np) = (c*yt-s*z(np))/offset
    ldy current_point
    lda y_coords, y         ; yt -> a, temp_y
    sta temp_y 
    MULTIPLY_REGxA c_x        ; c * yt -> product2
    COPY_REG16 product_hi, product_lo, product2_hi, product2_lo
    ldy current_point         ; s * z(np)
    lda z_coords, y 
    sta temp_z              ; store for later
    MULTIPLY_REGxA s_x
; product2 = c * yt - s*z(np)
    SUB_REG16 product2_hi, product2_lo, product_hi, product_lo, product2_hi, product2_lo

    jsr divide_product2_128  ; divide result by 128

    ldy current_point         ; store rotated Y result
    lda product2_hi
    sta yd_coords, y




; compute zd(np) =(s*yt + c*z(np))/offset
    lda temp_y
    MULTIPLY_REGxA s_x        ; s * yt -> product2
    COPY_REG16 product_hi, product_lo, product2_hi, product2_lo

    ldy current_point 
    lda temp_z
    MULTIPLY_REGxA c_x        ; c * z(np) -> product 

; product2 = s*yt + c*z(np)
    ADD_REG16 product_hi, product_lo, product2_hi, product2_lo, product2_hi, product2_lo
    jsr divide_product2_128         ; divide product2 by 128

    ldy current_point 
    lda product2_hi
    sta zd_coords, y
    sta temp_z              ; used for the next formula 



; rotation about y axis 
; compute xd(np) = (c*xt+s*zt)/offset
    ldy current_point         ; xt -> a, temp_x
    lda x_coords, y 
    sta temp_x 
    MULTIPLY_REGxA c_y        ; c * xt -> product2
    COPY_REG16 product_hi, product_lo, product2_hi, product2_lo
    lda temp_z 
    MULTIPLY_REGxA s_y        ; s * zt

; product2 <---- product + s * zt
    ADD_REG16 product_hi, product_lo, product2_hi, product2_lo, product2_hi, product2_lo

    jsr divide_product2_128         ;divide product2 by 128

    ldy current_point 
    lda product2_hi
    sta xd_coords, y

; compute zd(np) =(c*zt-s*xt)/offset
    lda temp_z 
    MULTIPLY_REGxA c_y        ; product2 = c * zt 
    COPY_REG16 product_hi, product_lo, product2_hi, product2_lo

    lda temp_x  
    MULTIPLY_REGxA s_y        ; product = s * xt

; product2 = product2 - s*xt 
    SUB_REG16 product2_hi, product2_lo, product_hi, product_lo, product2_hi, product2_lo
    jsr divide_product2_128         ;divide prod by 128

    ldy current_point 
    lda product2_hi
    sta zd_coords, y

; next point
    iny
    sty current_point 
    cpy total_coords
    beq create_back
        jmp rotate_loop 

create_back:
.ifdef DOUBLE_SIDED
; create the back side by offsetting the front side
; subtract starting front coord from starting back coord
    dec total_coords
    ldy total_coords
    sec
    lda xd_coords,y
    sbc xd_coords
    sta temp_x

    sec
    lda yd_coords,y
    sbc yd_coords
    sta temp_y

    sec
    lda zd_coords,y
    sbc zd_coords
    sta temp_z

; add difference to all front coords
    iny    ; skip 1st coord
    ldx #1

create_back_loop:
    clc
    lda xd_coords,x
    adc temp_x
    sta xd_coords,y

    clc
    lda yd_coords,x
    adc temp_y
    sta yd_coords,y

    clc
    lda zd_coords,x
    adc temp_z
    sta zd_coords,y

    inx
    iny
    cpx total_coords
    beq project_it
        jmp create_back_loop
.endif ; DOUBLE_SIDED


; convert all the 3D coordinates to XY
project_it:
.ifdef DOUBLE_SIDED
    asl total_coords        ; double the coordinates to process both sides
.endif
    lda #0                  ; the current point
    sta current_point 

project_loop:
    ldy current_point 
; get the projection coefficient based on signed Z 
    ldx zd_coords, y 
    lda proj_table, x
    sta proj_coef


; scale X based on projection coefficient
    sta multiply_a
    lda xd_coords, y 
    sta multiply_b 
    jsr multiply_ab8        ; projpos or neg * xd_coords 
    jsr divide_product_64       ; product /= 64
    ldy current_point 

; center X
    clc
    lda product_hi
    adc #128
    sta vex,y                 ;x vertex 

; scale Y based on projection coefficient
    lda yd_coords, y
    MULTIPLY_REGxA proj_coef
    jsr divide_product_64       ; product /= 64
    ldy current_point 

; center Y
    clc
    lda product_hi
    adc #100
    sta vey,y                 ;y vertex 

; next point
    iny
    sty current_point 
    cpy total_coords
    beq draw_it
        jmp project_loop 


draw_it:
; draw front side
.ifdef DOUBLE_SIDED
    lsr total_coords
.endif
    lda #0
    sta start_point
    lda total_coords
    sta end_point
    jsr draw_closed_polygon

.ifdef DOUBLE_SIDED
; draw back side
    lda total_coords
    sta start_point
    sta end_point
    asl end_point ; shift to end of back side
    jsr draw_closed_polygon

    jsr draw_joiners
.endif

; end do_rotate
    rts




draw_closed_polygon:
; load starting point
    ldy start_point
    sty current_point 
    lda vex, y
    sta x1_lo
    lda vey, y 
    sta y1 
    iny 

polygon_loop:
    lda vex, y
    sta x2_lo
    lda vey, y
    sta y2
; next point
    iny
    sty current_point
    jsr draw_line     ;line (vx(0), vy(0) - vx(1) ,vy(1)) 

; shift point2 to point1
    lda x2_lo
    sta x1_lo
    lda y2
    sta y1

    ldy current_point
    cpy end_point
    bne polygon_loop

; close the polygon
        ldy start_point
        lda vex, y
        sta x2_lo
        lda vey, y
        sta y2
        jsr draw_line     ;line (vx(0), vy(0) - vx(1) ,vy(1)) 
        rts


draw_joiners:
    lda #0
    sta current_point
    lda total_coords
    sta current_point2

joiner_loop:
    ldy current_point
    lda vex, y
    sta x1_lo
    lda vey, y
    sta y1
    
    ldy current_point2
    lda vex, y
    sta x2_lo
    lda vey, y
    sta y2
    
    jsr draw_line
    inc current_point
    inc current_point2
    lda current_point
    cmp total_coords
    bne joiner_loop
        rts

.include "common_code.inc"




.endproc
