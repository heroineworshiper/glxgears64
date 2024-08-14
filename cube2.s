; ported from
; https://retro64.altervista.org/blog/an-introduction-to-vector-based-graphics-the-commodore-64-rotating-simple-3d-objects/

; compile with make cube2





; rotate which axis.  Enable 1
;ROTATE_Y = 1
ROTATE_XY = 1

.include "common_vars.inc"

.segment	"DATA"

TOTAL_COORDS = 8

vex:       .res TOTAL_COORDS
vey:       .res TOTAL_COORDS                      

; rotated coordinates
xd_coords: .res TOTAL_COORDS
yd_coords: .res TOTAL_COORDS
zd_coords: .res TOTAL_COORDS


.segment	"RODATA"


;starting vertexes coordinates in two's complement form

; no clipping support
XSIZE = 50
YSIZE = 50
ZSIZE = 50
x_coords: 
    .byte    256-XSIZE, 256-XSIZE, XSIZE, XSIZE, 256-XSIZE, 256-XSIZE, XSIZE, XSIZE
y_coords: 
    .byte    256-YSIZE, YSIZE, YSIZE, 256-YSIZE, 256-YSIZE, YSIZE, YSIZE, 256-YSIZE
z_coords: 
    .byte    256-ZSIZE, 256-ZSIZE, 256-ZSIZE, 256-ZSIZE, ZSIZE, ZSIZE, ZSIZE, ZSIZE

.include "tables.inc"

.segment	"CODE"
.proc	_main: near

    jsr common_init
; override starting coord
    lda #10
    sta ry

cube_loop:
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


    lda #0                  ;loop counter for eight points (from 0 to 7)
    sta current_point 

; rotate 1 point
rotate_loop:
; computes yd(np) = (c*yt-s*z(np))/offset



.ifdef ROTATE_Y
    ldy current_point
    lda y_coords, y         ; yt -> a, temp_y
    sta temp_y 
    MULTIPLY_REGxA c_y        ; product2 = c * yt
    COPY_REG16 product_hi, product_lo, product2_hi, product2_lo

    ldy current_point 
    lda z_coords, y 
    MULTIPLY_REGxA s_y        ; product = s * z(np) 
; product2 = c * yt - s*z(np)
    SUB_REG16 product2_hi, product2_lo, product_hi, product_lo, product2_hi, product2_lo
    jsr divide_product2_128         ; divide product2 by 128

    ldy current_point 
    lda product2_hi
    sta yd_coords, y

; compute zd(np) =(s*yt + c*z(np))/offset
    lda temp_y
    MULTIPLY_REGxA s_y        ; product2 = s * yt
    COPY_REG16 product_hi, product_lo, product2_hi, product2_lo

    ldy current_point 
    lda z_coords, y 
    MULTIPLY_REGxA c_y        ; product = c * z(np) 

; product2 = s * yt + c * z(np) 
    ADD_REG16 product_hi, product_lo, product2_hi, product2_lo, product2_hi, product2_lo
    jsr divide_product2_128         ;divide prod by 128

    ldy current_point 
    lda product2_hi
    sta zd_coords, y
    lda x_coords, y
    sta xd_coords, y     ; x stays the same 

.endif ; ROTATE_Y



.ifdef ROTATE_XY
; rotation about x axis 
; compute yd(np) = (c*yt-s*z(np))/offset
    ldy current_point
    lda y_coords, y         ; yt -> a, temp_y
    sta temp_y 
    MULTIPLY_REGxA c_x        ; c * yt -> product2
    COPY_REG16 product_hi, product_lo, product2_hi, product2_lo
    ldy current_point         ; s * z(np)
    lda z_coords, y 
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
    lda z_coords, y 
    MULTIPLY_REGxA c_x        ; c * z(np) -> product 

; product2 = s*yt + c*z(np)
    ADD_REG16 product_hi, product_lo, product2_hi, product2_lo, product2_hi, product2_lo
    jsr divide_product2_128         ; divide product2 by 128

    ldy current_point 
    lda product2_hi
    sta zd_coords, y
    sta temp_z              ; used for the following formula 



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

.endif ; ROTATE_XY


; Y contains current point

; get the projection coefficient based on signed Z 
.ifndef ORTHOGANOL
    ldx zd_coords, y 
    lda proj_table, x
    sta proj_coef
; scale X based on projection coefficient
    sta multiply_a
.endif


    lda xd_coords, y 

.ifndef ORTHOGANOL
    sta multiply_b 
    jsr multiply_ab8        ; projpos or neg * xd_coords 
    jsr divide_product_64       ; product /= 64
    ldy current_point 
    lda product_hi
.endif


; center X
    clc
    adc #128
    sta vex,y                 ;x vertex 

; scale Y based on projection coefficient
    lda yd_coords, y

.ifndef ORTHOGANOL
    MULTIPLY_REGxA proj_coef
    jsr divide_product_64       ; product /= 64
    ldy current_point 
    lda product_hi
.endif

; center Y
    clc
    adc #100
    sta vey,y                 ;y vertex 

; next point
    iny
    sty current_point 
    cpy #TOTAL_COORDS
    beq draw_it
        jmp rotate_loop 


draw_it:
;draws the cube
    jsr clear_part

    lda #$00
    ldy #$00
    sta draw_count 

    lda vex, y
    sta x1_lo
    lda vey, y 
    sta y1 

    iny 
    inc draw_count 

    lda vex, y
    sta x2_lo 
    lda vey, y
    sta y2 

    jsr draw_line     ;line (vx(0), vy(0) - vx(1) ,vy(1)) 


    ldy draw_count 

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    iny 
    inc draw_count 

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 


    jsr draw_line     ;line (vx(1), vy(1) - vx(2), vy(2)) 

    ldy draw_count 

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    iny 
    inc draw_count 

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(2), vy(2) - vx(3), vy(3)) 

    ldy draw_count 

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    ldy #0
    sty draw_count

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(3), vy(3) - vx(1), vy(1)) 

    ldy #4
    sty draw_count

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    iny 
    inc draw_count 

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(4), vy(4) - vx(5), vy(5)) 

    ldy draw_count 

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    iny 
    inc draw_count 

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(5), vy(5) - vx(6), vy(6)) 

    ldy draw_count 

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    iny 
    inc draw_count 

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(6), vy(6) - vx(7), vy(7)) 

    ldy draw_count 

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    ldy #04
    sty draw_count 

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(7), vy(7) - vx(4), vy(4)) 

    ldy #00

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    ldy #4

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(0), vy(0) - vx(4), vy(4)) 

    ldy #03

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    ldy #7

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(3), vy(3) - vx(7), vy(7)) 

    ldy #01

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    ldy #5

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(1), vy(1) - vx(5), vy(5)) 

    ldy #02

    lda vex, y 
    sta x1_lo

    lda vey, y
    sta y1 


    ldy #6

    lda vex, y
    sta x2_lo
    lda vey, y 
    sta y2 

    jsr draw_line     ;line (vx(2), vy(2) - vx(6), vy(6))


; cube drawn
    jsr swap_screen

; user rotation
.ifdef INTERACTIVE
    jsr getc
.else
; automatic XY rotation
    inc rx
    inc rx
    inc rx
    inc rx
    inc rx
    inc rx
    inc rx
    inc rx
;    inc ry
.endif

; repeat
    jmp cube_loop







.include "common_code.inc"


.endproc
