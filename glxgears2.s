; Glxgears using the budge 3-D Graphics System
; 
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

.include "cbm_kernal.inc"
.include "common.inc"


; different gear colors in 1 the starting position
;.define COLOR

BMP0 = $6000
BMP0C = $6020 ; offset by 4 columns to center the graphics
BMP0_SCREEN = $5c00
BMP1 = $a000
BMP1C = $a020 ; offset by 4 columns to center the graphics
BMP1_SCREEN = $8000



; self modifying code
OpDEY := $88 ;DEY opcode
OpINY := $c8 ;INY opcode
OpDEX := $ca ;DEX opcode
OpINX := $e8 ;INX opcode
OpNOP := $ea ;NOP opcode

; globals
current_page := $02 ; Current hi-res page id.
zrot1 := $03  ; z rotations of the 3 gears
zrot2 := $04
zrot3 := $05
xrot_g := $0c ; user input rotations 0-127
yrot_g := $0d
is_animated := $0e
temp1 := $fb
temp2 := $fc
temp3 := $fd
temp4 := $fe

; DrawLineList
hptr       := $06 ; 2 bytes
xstart     := $1c 
ystart     := $1d 
xend       := $1e 
yend       := $1f 
delta_x    := $3c 
delta_y    := $3d 
line_adj   := $3e
last_line_start  := $3f ; 2 bytes
ysave      := $44 

; CompTransform
xc          := $19 ; transformed X coordinate
yc          := $1a ; transformed Y coordinate
zc          := $1b ; transformed Z coordinate
xposn       := $1d ; global X coordinate (0-255)
yposn       := $1e ; global Y coordinate (0-199)
zrot        := $1f ; Z rotation ($00-1B)
yrot        := $3c ; Y rotation ($00-1B)
xrot        := $3d ; X rotation ($00-1B)
rot_tmp     := $3f ; 4 bytes
out_index   := $43
last_point  := $44
xlocal      := $45 ; local coordinate after rotating Z
ylocal      := $46


GLOBAL_X := 127
GLOBAL_Y := 100

.segment "DATA"


.segment	"START"

    .byte $01, $08, $0b, $08, $13, $02, $9e, $32, $30, $36, $31, $00, $00, $00

.segment	"CODE"

jmp mane

mane:
    INIT_DEBUG
; switch out BASIC ROM
    lda #KERNAL_IN
    sta PORT_REG

; bitmap mode https://sta.c64.org/cbm64mem.html
    lda	#$bb
	sta	$d011		

; border color
	lda	#$0e
	sta	$d020
	sta	$d021

    lda #0
    sta current_page
; set up the bitmap
    jsr flip_page
    jsr clear
    jsr flip_page
    jsr clear

	lda	$d018       ; set bitmap memory relative to VIC bank
	and	#%11110000
	ora	#%00001000  ; vic bank + $2000
	sta	$d018	

; set color memory to white pen on dark blue paper (also clears sprite pointers) on screen 2
	ldx	#$00
	lda	#$10
loopcol:
	sta	BMP0_SCREEN,x	
	sta	BMP0_SCREEN+$100,x
	sta	BMP0_SCREEN+$200,x
	sta	BMP0_SCREEN+$300,x
    sta	BMP1_SCREEN,x	
	sta	BMP1_SCREEN+$100,x
	sta	BMP1_SCREEN+$200,x
	sta	BMP1_SCREEN+$300,x
	inx
	bne	loopcol

.ifdef COLOR
; set different colors for static gear positions
    ldy #0
loopgear2y:
    ldx #13
loopgear2x:
    lda #$60
loopgear2x_mod1:
    sta BMP0_SCREEN,x
loopgear2x_mod2:
    sta BMP1_SCREEN,x
    inx
    cpx #22
    bne loopgear2x
        ADD_LITERAL16 loopgear2x_mod1 + 1, loopgear2x_mod1 + 1, 40
        ADD_LITERAL16 loopgear2x_mod2 + 1, loopgear2x_mod2 + 1, 40
        iny
        cpy #10
        bne loopgear2y

    ldy #0
loopgear1y:
    ldx #10
loopgear1x:
    lda #$20
loopgear1x_mod1:
    sta BMP0_SCREEN + 10 * 40,x
loopgear1x_mod2:
    sta BMP1_SCREEN + 10 * 40,x
    inx
    cpx #24
    bne loopgear1x
        ADD_LITERAL16 loopgear1x_mod1 + 1, loopgear1x_mod1 + 1, 40
        ADD_LITERAL16 loopgear1x_mod2 + 1, loopgear1x_mod2 + 1, 40
        iny
        cpy #14
        bne loopgear1y


    ldy #0
loopgear3y:
    ldx #24
loopgear3x:
    lda #$50
loopgear3x_mod1:
    sta BMP0_SCREEN + 11 * 40,x
loopgear3x_mod2:
    sta BMP1_SCREEN + 11 * 40,x
    inx
    cpx #31
    bne loopgear3x
        ADD_LITERAL16 loopgear3x_mod1 + 1, loopgear3x_mod1 + 1, 40
        ADD_LITERAL16 loopgear3x_mod2 + 1, loopgear3x_mod2 + 1, 40
        iny
        cpy #9
        bne loopgear3y

.endif ; COLOR



; clear entire bitmap
    jsr clear_BMP0_full
    jsr clear_BMP1_full


    SELECT_PRINTER
    PRINT_TEXT welcome


; initialize it
    SET_LITERAL8 zrot1, 0
    SET_LITERAL8 zrot2, 1
    SET_LITERAL8 zrot3, 8
    SET_LITERAL8 xrot_g, 4
    SET_LITERAL8 yrot_g, 4
    SET_LITERAL8 is_animated, 0

loop:
.ifndef USE_XOR
    jsr clear
.endif


; set variables for the transform


; gear 1
CENTER_X := 20
CENTER_Y := 5
    SET_LITERAL8 xposn, GLOBAL_X
    SET_LITERAL8 yposn, GLOBAL_Y
    COPY_REG8 xrot, xrot_g
    COPY_REG8 yrot, yrot_g
    COPY_REG8 zrot, zrot1
    SET_LITERAL8 xlocal, (CENTER_X - 40)
    SET_LITERAL8 ylocal, (CENTER_Y - 30)
    SET_LITERAL8 last_point, Gear1TotalPoints
 
    SET_LITERAL16 xcoordsmod + 1, Gear1XCoords
    SET_LITERAL16 ycoordsmod + 1, Gear1YCoords
    SET_LITERAL16 zcoordsmod + 1, Gear1ZCoords
    jsr CompTransform     ; transform all points

; set variables for the draw
    SET_LITERAL16 linestartmod + 1, Gear1LineStart
    SET_LITERAL16 lineendmod + 1, Gear1LineEnd
    SET_LITERAL16 last_line_start, Gear1LastLineStart
    jsr DrawLineList     ; draw it


; gear 2
    SET_LITERAL8 xposn, GLOBAL_X
    SET_LITERAL8 yposn, GLOBAL_Y
    COPY_REG8 xrot, xrot_g
    COPY_REG8 yrot, yrot_g
    COPY_REG8 zrot, zrot2
    SET_LITERAL8 xlocal, (CENTER_X - 40)
    SET_LITERAL8 ylocal, (CENTER_Y + 47)
    SET_LITERAL8 last_point, Gear2TotalPoints
 
    SET_LITERAL16 xcoordsmod + 1, Gear2XCoords
    SET_LITERAL16 ycoordsmod + 1, Gear2YCoords
    SET_LITERAL16 zcoordsmod + 1, Gear2ZCoords
    jsr CompTransform     ; transform all points

; set variables for the draw
    SET_LITERAL16 linestartmod + 1, Gear2LineStart
    SET_LITERAL16 lineendmod + 1, Gear2LineEnd
    SET_LITERAL16 last_line_start, Gear2LastLineStart
    jsr DrawLineList     ; draw it


; gear3
    SET_LITERAL8 xposn, GLOBAL_X
    SET_LITERAL8 yposn, GLOBAL_Y
    COPY_REG8 xrot, xrot_g
    COPY_REG8 yrot, yrot_g
    COPY_REG8 zrot, zrot3
    SET_LITERAL8 xlocal, (CENTER_X + 35)
    SET_LITERAL8 ylocal, (CENTER_Y - 30)
    SET_LITERAL8 last_point, Gear3TotalPoints
 
    SET_LITERAL16 xcoordsmod + 1, Gear3XCoords
    SET_LITERAL16 ycoordsmod + 1, Gear3YCoords
    SET_LITERAL16 zcoordsmod + 1, Gear3ZCoords
    jsr CompTransform     ; transform all points

; set variables for the draw
    SET_LITERAL16 linestartmod + 1, Gear3LineStart
    SET_LITERAL16 lineendmod + 1, Gear3LineEnd
    SET_LITERAL16 last_line_start, Gear3LastLineStart
    jsr DrawLineList     ; draw it



    jsr flip_page

    jsr GETIN
    beq keyboard_done ; got $00
        cmp #' '
        bne keyboard1
            lda is_animated
            eor #1
            sta is_animated
            jmp keyboard_done

STEP := 2
keyboard1:
    cmp #$91     ; up
    bne keyboard2
        SUB_LITERAL xrot_g, xrot_g, STEP
        jmp keyboard_done
keyboard2:
    cmp #$11     ; down
    bne keyboard3
        ADD_LITERAL xrot_g, xrot_g, STEP
        jmp keyboard_done
keyboard3:
    cmp #$9d     ; left
    bne keyboard4
        SUB_LITERAL yrot_g, yrot_g, STEP
        jmp keyboard_done
keyboard4:
    cmp #$1d     ; right
    bne keyboard_done
        ADD_LITERAL yrot_g, yrot_g, STEP
        jmp keyboard_done

keyboard_done:
    PRINT_TEXT animated
    PRINT_HEX8 is_animated
    PRINT_TEXT xrot_t
    PRINT_HEX8 xrot_g
    PRINT_TEXT yrot_t
    PRINT_HEX8 yrot_g
    lda #$0a
    jsr CIOUT
    lda #$00
    jsr CIOUT


; rotate Z
    dec zrot1
    lda zrot1
    and #$7f
    sta zrot1

    inc zrot2
    inc zrot2
    lda zrot2
    and #$7f
    sta zrot2

    inc zrot3
    inc zrot3
    lda zrot3
    and #$7f
    sta zrot3

    lda is_animated
    beq not_animated
; automatic XY rotation
        inc yrot_g
        inc yrot_g

;        inc xrot_g
;        inc xrot_g

not_animated:
    lda yrot_g
    and #$7f
    sta yrot_g
    lda xrot_g
    and #$7f
    sta xrot_g
    jmp loop

hang:
    jmp hang
    rts







flip_page:
; wait for raster line >= 256
    lda $d011
    bpl flip_page

    lda #1
    eor current_page
    sta current_page
    cmp #0
    bne flip_page2 ; current_page == 1

; display BMP0, draw BMP1
; https://sta.c64.org/cbm64mem.html
	    lda $d018
	    and	#%00001111  ; set color memory relative to VIC bank
	    ora	#%01110000  ; vic bank + $1c00
	    sta	$d018

        lda	$dd00		; set the VIC bank
	    and	#%11111100
	    ora	#%00000010  ; $4000
	    sta	$dd00

        ldx #<YTableHi_BMP1
        ldy #>YTableHi_BMP1
        jmp flip_page3

flip_page2:
; display BMP1, draw BMP0
	lda $d018           ; set color memory relative to VIC bank
	and	#%00001111
	ora	#%00000000      ; VIC II only sees character ROM at $9000
	sta	$d018

	lda	$dd00		    ; set the VIC bank
	and	#%11111100
	ora	#%00000001      ; $8000
	sta	$dd00

    ldx #<YTableHi_BMP0
    ldy #>YTableHi_BMP0
flip_page3:
    stx ytablemod1 + 1
    stx ytablemod2 + 1
    stx ytablemod3 + 1
    sty ytablemod1 + 2
    sty ytablemod2 + 2
    sty ytablemod3 + 2
    rts


; clear entire screen
clear_BMP1_full:
	ldy	#32
    lda	#<BMP1	; set starting address
	sta	modfull1 + 1
	lda	#>BMP1
	sta	modfull1 + 2	
    jmp loop_clear_full

clear_BMP0_full:
	ldy	#32
    lda	#<BMP0	; set starting address
	sta	modfull1 + 1
	lda	#>BMP0
	sta	modfull1 + 2	

loop_clear_full:
	ldx	#250
	lda	#$00            ;filling value 
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
clear:
    lda current_page 
    beq clear_BMP1 ; current_page == 0

clear_BMP0:
; clear cols 0 - 255
    lda #$00
    ldx #0
; loop 256 times
clear_BMP0_loop:
    sta BMP0C+0*320,x
    sta BMP0C+1*320,x
    sta BMP0C+2*320,x
    sta BMP0C+3*320,x
    sta BMP0C+4*320,x
    sta BMP0C+5*320,x
    sta BMP0C+6*320,x
    sta BMP0C+7*320,x
    sta BMP0C+8*320,x
    sta BMP0C+9*320,x
    sta BMP0C+10*320,x
    sta BMP0C+11*320,x
    sta BMP0C+12*320,x
    sta BMP0C+13*320,x
    sta BMP0C+14*320,x
    sta BMP0C+15*320,x
    sta BMP0C+16*320,x
    sta BMP0C+17*320,x
    sta BMP0C+18*320,x
    sta BMP0C+19*320,x
    sta BMP0C+20*320,x
    sta BMP0C+21*320,x
    sta BMP0C+22*320,x
    sta BMP0C+23*320,x
    sta BMP0C+24*320,x
    inx
    bne	clear_BMP0_loop
        rts




clear_BMP1:
; clear cols 0 - 255
    lda #$00
    ldx #0
; loop 256 times
clear_BMP1_loop:
    sta BMP1C+0*320,x
    sta BMP1C+1*320,x
    sta BMP1C+2*320,x
    sta BMP1C+3*320,x
    sta BMP1C+4*320,x
    sta BMP1C+5*320,x
    sta BMP1C+6*320,x
    sta BMP1C+7*320,x
    sta BMP1C+8*320,x
    sta BMP1C+9*320,x
    sta BMP1C+10*320,x
    sta BMP1C+11*320,x
    sta BMP1C+12*320,x
    sta BMP1C+13*320,x
    sta BMP1C+14*320,x
    sta BMP1C+15*320,x
    sta BMP1C+16*320,x
    sta BMP1C+17*320,x
    sta BMP1C+18*320,x
    sta BMP1C+19*320,x
    sta BMP1C+20*320,x
    sta BMP1C+21*320,x
    sta BMP1C+22*320,x
    sta BMP1C+23*320,x
    sta BMP1C+24*320,x
    inx
    bne	clear_BMP1_loop
        rts


; 
; Draw a list of lines using exclusive-or, which inverts the pixels.  Drawing
; the same thing twice erases it.
; 
; On entry:
;  $45 - index of first line
;  $46 - index of last line
;  XCoord_0E/YCoord_0F or XCoord_10/YCoord_11 have transformed points in screen
; coordinates
; 
; When the module is configured for OR-mode drawing, this code is replaced with
; a dedicated erase function.  The erase code is nearly identical to the draw
; code, but saves a little time by simply zeroing out whole bytes instead of
; doing a read-modify-write.

DrawLineList:
DrawLoop:
linestartmod:    ldy     $ffff            ; FirstLineStartAddress
_0E_or_10_1:     lda     XCoord0,y   ; the instructions here are modified to load from
                 sta     xstart           ; the appropriate set of X/Y coordinate tables
_0F_or_11_1:     lda     YCoord0,y
                 sta     ystart
lineendmod:      ldy     $ffff            ; FirstLineEndAddress
_0E_or_10_2:     lda     XCoord0,y 
                 sta     xend
_0F_or_11_2:     lda     YCoord0,y
                 sta     yend
; Prep the line draw code.  We need to compute deltaX/deltaY, and set a register
; increment / decrement / no-op instruction depending on which way the line is
; going.
                lda     xstart            ; compute delta X
                sec
                sbc     xend
                bcs     left_to_right     ; left to right
                eor     #$ff              ; right to left; invert value
                adc     #$01     
                ldy     #OpINX   
                bne     GotDeltaX

left_to_right:  beq     IsVertical        ; branch if deltaX=0
                ldy     #OpDEX   
                bne     GotDeltaX

IsVertical:     ldy     #OpNOP            ; fully vertical, use no-op
GotDeltaX:      sta     delta_x    
                sty     _InxDexNop1
                sty     _InxDexNop2
                lda     ystart            ; compute delta Y
                sec         
                sbc     yend
                bcs     L1A4E             ; end < start, we're good
                eor     #$ff              ; invert value
                adc     #$01     
                ldy     #OpINY   
                bne     GotDeltaY

L1A4E:          beq     IsHorizontal      ; branch if deltaY=0
                ldy     #OpDEY   
                bne     GotDeltaY

IsHorizontal:   ldy     #OpNOP            ; fully horizontal, use no-op
GotDeltaY:      sta     delta_y     
                sty     _InyDeyNop1 
                sty     _InyDeyNop2 
                ldx     xstart      
                ldy     ystart      
                lda     #$00        
                sta     line_adj    
                lda     delta_x     
                cmp     delta_y     
                bcs     HorizDomLine
; Line draw: vertically dominant (move vertically every step)
; 
; On entry: X=xpos, Y=ypos
VertDomLine:    cpy     yend              ;
                beq     LineDone          ;
_InyDeyNop1:    nop                       ; self-mod INY/DEY/NOP
                lda     YTableLo,y        ; new line, update Y position
                sta     hptr              ;
ytablemod1:     lda     YTableHi_BMP0,y   ;
                sta     hptr+1            ;
                lda     line_adj          ; Bresenham update
                clc                
                adc     delta_x    
                cmp     delta_y    
                bcs     NewColumn  
                sta     line_adj   
                bcc     SameColumn 

NewColumn:      sbc     delta_y    
                sta     line_adj   
_InxDexNop1:    nop                       ; self-mod INX/DEX/NOP
SameColumn:     sty     ysave             ;
                ldy     Div7Tab,x         ; XOR-draw the point
                lda     (hptr),y      
.ifdef USE_XOR
                eor     HiResBitTab,x
.else
                ora     HiResBitTab,x 
.endif
                sta     (hptr),y      
                ldy     ysave         
                jmp     VertDomLine   

LineDone:       INC16 linestartmod + 1
                INC16 lineendmod + 1
                BRANCH_GREATEREQUAL16_REG linestartmod + 1, last_line_start, DrawDone
                    jmp     DrawLoop

DrawDone:       rts             

; Line draw: horizontally dominant (move horizontally every step)
; 
; On entry: X=xpos, Y=ypos
HorizDomLine:   lda     YTableLo,y        ; set up hi-res pointer
                sta     hptr              ;
ytablemod2:     lda     YTableHi_BMP0,y   ;
                sta     hptr+1            ;
HorzLoop:       cpx     xend              ; X at end?
                beq     LineDone          ; yes, finish
_InxDexNop2:    nop                       ;
                lda     line_adj          ; Bresenham update
                clc                       ;
                adc     delta_y           ;
                cmp     delta_x           ;
                bcs     NewRow            ;
                sta     line_adj          ;
                bcc     SameRow           ;

NewRow:         sbc     delta_x           ;
                sta     line_adj          ;
_InyDeyNop2:    nop                       ;
                lda     YTableLo,y        ; update Y position
                sta     hptr              ;
ytablemod3:     lda     YTableHi_BMP0,y   ;
                sta     hptr+1            ;
SameRow:        sty     ysave             ;
                ldy     Div7Tab,x         ; XOR-draw the point
                lda     (hptr),y       
.ifdef USE_XOR
                eor     HiResBitTab,x 
.else
                ora     HiResBitTab,x  
.endif
                sta     (hptr),y       
                ldy     ysave          
                jmp     HorzLoop       





; Coordinate transformation function.  Transforms all points in a single object.
; 
; On entry:
;  xc 0-255
;  yc 0-200
;  zrot 00-27
;  yrot 00-27
;  xrot 00-27
;  first_point: index of first point to transform
;  last_point: index of last point to transform
; 
; 


CompTransform:

; angle is in Y
.macro COMPUTE_LO index_table, dst, dst2
; compute the magnitude 0 offset
    lda #0
    sta temp1
    lda index_table,y
    asl A                    ; left shift 4 bits
    rol temp1
    asl A
    rol temp1
    asl A
    rol temp1
    asl A
    rol temp1
    clc                      ; add temp1, A to table start
    adc #<RotTabLo
    sta dst + 1
    sta dst2 + 1
    lda temp1
    adc #>RotTabLo
    sta dst + 2
    sta dst2 + 2
.endmacro

; angle is in Y
.macro COMPUTE_HI index_table, dst, dst2
; compute the magnitude 0 offset
    lda index_table,y
    sta temp1 ; bits 4:5 into temp1
    lsr temp1
    lsr temp1
    lsr temp1
    lsr temp1
    and #$f   ; bits 0:3 into A
    clc 
    adc #<RotTabHi          ; add temp1, A to table start
    sta dst + 1
    sta dst2 + 1
    lda temp1
    adc #>RotTabHi
    sta dst + 2
    sta dst2 + 2
.endmacro

; Configure Z rotation.
                ldy     zrot
                COMPUTE_LO RotIndex_sin, _zrotLS1, _zrotLS2
                COMPUTE_LO RotIndex_cos, _zrotLC1, _zrotLC2
                COMPUTE_HI RotIndex_sin, _zrotHS1, _zrotHS2
                COMPUTE_HI RotIndex_cos, _zrotHC1, _zrotHC2
; Configure Y rotation.
                ldy     yrot
                COMPUTE_LO RotIndex_sin, _yrotLS1, _yrotLS2
                COMPUTE_LO RotIndex_cos, _yrotLC1, _yrotLC2
                COMPUTE_HI RotIndex_sin, _yrotHS1, _yrotHS2
                COMPUTE_HI RotIndex_cos, _yrotHC1, _yrotHC2
; Configure X rotation.
                ldy     xrot
                COMPUTE_LO RotIndex_sin, _xrotLS1, _xrotLS2
                COMPUTE_LO RotIndex_cos, _xrotLC1, _xrotLC2
                COMPUTE_HI RotIndex_sin, _xrotHS1, _xrotHS2
                COMPUTE_HI RotIndex_cos, _xrotHC1, _xrotHC2


; DEBUG
;                ldy zrot
;                COMPUTE_LO RotIndex_sin, test_sin_lo, test_sin_lo
;                COMPUTE_LO RotIndex_cos, test_cos_lo, test_cos_lo
;                COMPUTE_HI RotIndex_sin, test_sin_hi, test_sin_hi
;                COMPUTE_HI RotIndex_cos, test_cos_hi, test_cos_hi
;
;TEST_MAG_LO := $00 ; low nibble
;TEST_MAG_HI := $80 ; high nibble
;                ldy #TEST_MAG_LO
;test_sin_lo:    lda RotTabLo,y
;                sta temp1
;                ldy #TEST_MAG_HI
;test_sin_hi:    lda RotTabHi,y
;                clc
;                adc temp1
;                sta temp1
;
;                ldy #TEST_MAG_LO
;test_cos_lo:    lda RotTabLo,y
;                sta temp2
;                ldy #TEST_MAG_HI
;test_cos_hi:    lda RotTabHi,y
;                clc
;                adc temp2
;                sta temp2
;
;                PRINT_HEX8 zrot
;                PRINT_HEX8 temp1
;                PRINT_HEX8 temp2
;                lda #$0a
;                jsr CIOUT
                
                ldx     #0  ; the point number

; 
; Now that we've got the code modified, perform the computation for all points
; in the object.
; 
TransformLoop:
xcoordsmod:     lda     $ffff,x ; ShapeXCoords
                sta     xc
ycoordsmod:     lda     $ffff,x ; ShapeYCoords
                sta     yc
zcoordsmod:     lda     $ffff,x ; ShapeZCoords
                sta     zc

                stx     out_index        ; save for later

;                PRINT_TEXT transformloop1
;                PRINT_HEX8 xc
;                PRINT_HEX8 yc
;                PRINT_HEX8 zc
;                lda #$0a
;                jsr CIOUT


DoZrot:         lda     xc               ;  rotating about Z, so we need to update X/Y coords
                and     #$0f             ;  split X/Y into nibbles
                sta     rot_tmp   
                lda     xc        
                and     #$f0      
                sta     rot_tmp+1 
                lda     yc        
                and     #$0f      
                sta     rot_tmp+2 
                lda     yc        
                and     #$f0      
                sta     rot_tmp+3 
                ldy     rot_tmp          ;  transform X coord
                ldx     rot_tmp+1        ;  XC = X * cos(theta) - Y * sin(theta)
_zrotLC1:       lda     RotTabLo,y
                clc               
_zrotHC1:       adc     RotTabHi,x
                ldy     rot_tmp+2 
                ldx     rot_tmp+3 
                sec               
_zrotLS1:       sbc     RotTabLo,y
                sec               
_zrotHS1:       sbc     RotTabHi,x
                sta     xc                ;  save updated coord
_zrotLC2:       lda     RotTabLo,y        ; transform Y coord
                clc                       ;  YC = Y * cos(theta) + X * sin(theta)
_zrotHC2:       adc     RotTabHi,x  
                ldy     rot_tmp     
                ldx     rot_tmp+1   
                clc                 
_zrotLS2:       adc     RotTabLo,y  
                clc                 
_zrotHS2:       adc     RotTabHi,x  
                sta     yc               ;  save updated coord

; DEBUG
;                jmp skip_rot


DoYrot:
                clc                  ; add local x translation
                lda xlocal
                adc     xc               ;  rotating about Y, so update X/Z
                sta     xc
                and     #$0f        
                sta     rot_tmp     
                lda     xc          
                and     #$f0        
                sta     rot_tmp+1   
                lda     zc          
                and     #$0f        
                sta     rot_tmp+2   
                lda     zc          
                and     #$f0        
                sta     rot_tmp+3   
                ldy     rot_tmp     
                ldx     rot_tmp+1   
_yrotLC1:       lda     RotTabLo,y  
                clc                 
_yrotHC1:       adc     RotTabHi,x  
                ldy     rot_tmp+2   
                ldx     rot_tmp+3   
                sec                 
_yrotLS1:       sbc     RotTabLo,y  
                sec                 
_yrotHS1:       sbc     RotTabHi,x  
                sta     xc          
_yrotLC2:       lda     RotTabLo,y  
                clc                 
_yrotHC2:       adc     RotTabHi,x  
                ldy     rot_tmp     
                ldx     rot_tmp+1   
                clc                 
_yrotLS2:       adc     RotTabLo,y  
                clc                 
_yrotHS2:       adc     RotTabHi,x  
                sta     zc          

DoXrot:         lda     zc           ; rotating about X, so update Z/Y
                and     #$0f      
                sta     rot_tmp   
                lda     zc        
                and     #$f0      
                sta     rot_tmp+1
                clc                  ; add local y translation
                lda     yc
                adc     ylocal
                sta     yc
                and     #$0f      
                sta     rot_tmp+2 
                lda     yc
                and     #$f0      
                sta     rot_tmp+3 
                ldy     rot_tmp   
                ldx     rot_tmp+1 
_xrotLC1:       lda     RotTabLo,y
                clc               
_xrotHC1:       adc     RotTabHi,x
                ldy     rot_tmp+2 
                ldx     rot_tmp+3 
                sec               
_xrotLS1:       sbc     RotTabLo,y
                sec               
_xrotHS1:       sbc     RotTabHi,x
                sta     zc        
_xrotLC2:       lda     RotTabLo,y
                clc               
_xrotHC2:       adc     RotTabHi,x
                ldy     rot_tmp   
                ldx     rot_tmp+1 
                clc               
_xrotLS2:       adc     RotTabLo,y
                clc               
_xrotHS2:       adc     RotTabHi,x
                sta     yc        



;                PRINT_TEXT transform_loop2
;                PRINT_HEX8 xc
;                PRINT_HEX8 yc
;                PRINT_HEX8 zc
;                lda #$0a
;                jsr CIOUT

; 
; Apply translation.
; 
; This is the final step, so the result is written to the transformed-point
; arrays.
; 
DoTranslate:    ldx     out_index        
                lda     xc               
                clc
                adc     xposn            ; object center in screen coordinates
_0E_or_10_3:    sta     XCoord0,x    
                lda     yposn           
                sec
                sbc     yc              
_0F_or_11_3:    sta     YCoord0,x    
                inx
                cpx     last_point       ; done?
                beq     TransformDone    ; yes, bail
                    jmp     TransformLoop    

TransformDone:  rts                      




welcome:
    .byte "------------------------------"
    .byte $0a
    .byte "welcome to glxgears on budge64"
    .byte $0a
    .byte "------------------------------"
    .byte $0a, $0a, $00    ; null terminator for the message
transformloop1:
    .byte "transformloop1 "
    .byte $00    ; null terminator for the message
transformloop2:
    .byte "transformloop2 "
    .byte $00    ; null terminator for the message

animated:
    .byte "animated "
    .byte $00    ; null terminator for the message
xrot_t:
    .byte "xrot "
    .byte $00    ; null terminator for the message
yrot_t:
    .byte "yrot "
    .byte $00    ; null terminator for the message


.include "common.s"


.include "tables2.s"
.include "gearmodel.s"






