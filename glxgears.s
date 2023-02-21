; compile with make glxgears


.include "common_vars.inc"


.segment	"DATA"


MAX_COORDS = 100

; total coordinates to draw
total_coords: .res 1
; Z rotation of gears
rz:           .res	1

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
    jmp mane
.res $7700

mane:
    jsr common_init


cube_loop:
; draw gear1
    lda #GEAR1_TEETH_N      ; must be a multiple of 4
;    lda #16 
    sta total_coords

; convert polar to XYZ with Z rotation
    ldy #0                  ; the current point
polar_loop:
    lda gear1_teeth_a, y    ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
    lda sin_gear1_outer1, x ; y = R1 * sin(angle)
    sta y_coords, y
    lda cos_gear1_outer1, x ; x = R1 * cos(angle)
    sta x_coords, y
    lda #00                 ; Z = 0
    sta z_coords, y
    iny

    lda gear1_teeth_a, y    ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
    lda sin_gear1_outer2, x ; y = R2 * sin(angle)
    sta y_coords, y
    lda cos_gear1_outer2, x ; x = R2 * cos(angle)
    sta x_coords, y
    lda #00                 ; Z = 0
    sta z_coords, y
    iny

    lda gear1_teeth_a, y    ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
    lda sin_gear1_outer2, x ; y = R2 * sin(angle)
    sta y_coords, y
    lda cos_gear1_outer2, x ; x = R2 * cos(angle)
    sta x_coords, y
    lda #00                 ; Z = 0
    sta z_coords, y
    iny

    lda gear1_teeth_a, y    ; angle of polygon point
    adc rz                  ; rotate about Z
    tax
    lda sin_gear1_outer1, x ; y = R1 * sin(angle)
    sta y_coords, y
    lda cos_gear1_outer1, x ; x = R1 * cos(angle)
    sta x_coords, y
    lda #00                 ; Z = 0
    sta z_coords, y
    iny

    cpy total_coords
        bne polar_loop



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


; rotate the polygon about XY
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
        jmp rotate_loop 
                
				
draw_it:
    jsr clear_part
    jsr draw_closed_polygon
    jsr swap_screen

; user rotation
.ifdef INTERACTIVE
    jsr getc
.else

; automatic XY rotation
;    inc rx
;    inc ry
    inc rz
.endif

; repeat
    jmp cube_loop


draw_closed_polygon:
; load starting point
    ldy #$00
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
    cpy total_coords
    bne polygon_loop

; close the polygon
        ldy #$00
        lda vex, y
        sta x2_lo
        lda vey, y
        sta y2
        jsr draw_line     ;line (vx(0), vy(0) - vx(1) ,vy(1)) 
        rts



.include "common_code.inc"




.endproc
