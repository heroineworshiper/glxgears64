; Program: 3D cube - Marcello of Retro64 Blog

* = $801

byteaddr = $fc		;fc, fd used



basic		byte	11,8,10,0,158,50,48,54,49,0,0,0
               
                
					;basic program for autostart
                                        
                                        
	
		bmpscreen = 24576	;bmpscreen start
                bmpscreen2 = 8192       ;alternate bmpscreen start 
                
                lda #<bmpscreen
                sta actual_screen+1
                lda #>bmpscreen
                sta actual_screen
                
                lda #<bmpscreen2
                sta actual_screen+3
                lda #>bmpscreen2
                sta actual_screen+2
                
                
		
                
                lda     #1
                sta     switch_flag      ;initialize flag for double-buffering 


		lda	#>bmpscreen	;initialize self-mod code
		sta	mod1+2
		lda	#<bmpscreen
		sta	mod1+1	
		

		lda	#5
		sta	$d020
		sta	$d021
                
                ldy	#187
		sty	$d011		;bitmap mode
			
		lda	$dd02
		ora	#3
		sta	$DD02		;CIA-2 I/O default value 		

		lda	$dd00		;CIA-2 bank 1 for VIC
		and	#252
		ora	#2
		sta	$dd00

		lda 	$d018
		and	#15
		ora	#112
		sta	$d018		;matrix from 16384+7168=23552

		lda	$d018
		and	#240
		ora	#8
		sta	$d018		;bmp base from 16384+8192 = 24576		
		


; set white pen on dark blue paper (also clears sprite pointers) on screen 2 

		ldx	#$00
		lda	#22
loopcol		sta	23552,x		;sta	$400,x
		sta	23552+256,x	;sta	$500,x
		sta	23552+512,x	;sta	$600,x
		sta	23552+768,x	;sta	$700,x
		inx
		bne	loopcol

; set white pen on dark blue paper (also clears sprite pointers) on screen 1

		ldx	#$00
		lda	#22
loopcol2        sta	1024,x		;sta	$400,x
		sta	1024+256,x	;sta	$500,x
		sta	1024+512,x	;sta	$600,x
		sta	1024+768,x	;sta	$700,x
		inx
		bne	loopcol2

                jsr     clear_screen2
                jsr     clear_screen1
               
               
                ; draw 3d cube
                
                lda #0
                sta rx                  ;set rotation angle to 0
                
cube_loop       ldx rx

                lda cos_tables, x
                sta c 
                
                lda sin_tables, x 
                sta s 

                lda #0                  ;loop counter for eight points (from 0 to 7)
                sta point_index 
                
rotate_loop     ; computes yd(np) = (c*yt-s*z(np))/offset

                ldy point_index 
                
                lda y_component, y 

                
                sta temp_y 
                
                lda c
                sta multiplicand8
                lda temp_y
                sta multiplier8 
                
                jsr multiply_ab8        ;c * yt
                
                lda multiplier8
                sta prod
                lda sum8
                sta prod+1              ;prod <--- c * yt
                
                ldy point_index 
                
                lda s
                sta multiplicand8
                lda z_component, y 
                sta multiplier8 
                
                jsr multiply_ab8        ;s*z(np) 
                
                sec
                lda prod+1
                sbc sum8
                sta prod+1
                lda prod
                sbc multiplier8
                sta prod                ;prod<---- prod-s*z(np) 
                
                jsr divide_prod_signed         ;divide prod by offset 64
                
                ldy point_index 
                
                lda prod+1
                sta yd_component, y
                
                
                
                
		;computes zd(np) =(s*yt + c*z(np))/offset
                
                                
                lda s
                sta multiplicand8
                lda temp_y
                sta multiplier8 
                
                jsr multiply_ab8        ;s * yt
                
                lda multiplier8
                sta prod
                lda sum8
                sta prod+1              ;prod <--- s * yt
                
                ldy point_index 
                
                lda c
                sta multiplicand8
                lda z_component, y 
                sta multiplier8 
                
                jsr multiply_ab8        ;c*z(np) 
                
                clc
                lda prod+1
                adc sum8
                sta prod+1
                lda prod
                adc multiplier8
                sta prod                ;prod<---- prod+c*z(np) 
                
                jsr divide_prod_signed         ;divide prod by offset 64
                
                ldy point_index 
                
                lda prod+1
                sta zd_component, y
                
                
                
                lda x_component, y
                sta xd_component, y     ;rem x stays the same 
                
                 
                
                ;projects xd 
                
                lda zd_component, y 
                bpl positive_zd
                
                sec
                lda #$00
                sbc zd_component,y 
                tax                     ;takes complement of zd and puts it in x 
                
                lda projneg, x          ;loads negative value of projection coefficient
                
                
                jmp skip_positive_zd


positive_zd
                ldx zd_component, y    
                
                lda projpos, x          ;loads positive value of projection coefficient 
                
skip_positive_zd
                
                sta multiplicand8
                lda xd_component, y 
                sta multiplier8 
                
                
                jsr multiply_ab8        ;projpos or neg * xd_component 
                
                jsr divide_signed         ;/ 64
                
                ldy point_index 
                
                clc
                lda sum8
                adc #160
                sta vex,y                 ;x vertex 
                
                
                
                ;jmp here 
                
                ;projects yd 
                
                lda zd_component, y 
                bpl positive_zd2
                
                sec
                lda #$00
                sbc zd_component,y 
                tax                     ;takes complement of zd and puts it in x 
                
                lda projneg, x          ;loads negative value of projection coefficient
                 
                
                jmp skip_positive_zd2


positive_zd2
                ldx zd_component, y    
                
                lda projpos, x          ;loads positive value of projection coefficient 
                
skip_positive_zd2
                
                sta multiplicand8
                lda yd_component, y     ;now project yd  
                sta multiplier8 
                
                
                jsr multiply_ab8        ;projpos or neg * xd_component 
                
                jsr divide_signed         ;/ 64
                
                ldy point_index 
                
                clc
                lda sum8
                adc #100
                sta vey,y                 ;y vertex 
                
                
                
                inc point_index 
                
                lda point_index 
                cmp #08
                bne jump_rotate_loop
                
                jmp here 
                
jump_rotate_loop
                jmp rotate_loop 
                
				
 here           

                ;draws the cube
                
                lda switch_flag 
                bne use_screen2 
                
                jsr clear_part1         ;clears first buffer
                                        ;switch from buffer2 to buffer1 
                
                                        
                
                
                jmp skip_use_screen2
                
use_screen2     jsr clear_part2         ;clears second buffer 
                                        ;start base on plot: actual_screen+2, actual_screen+3
                                        ;switch from buffer 1 to buffer 2 
                                        
                
                
skip_use_screen2 
                

                
                lda #$00
                sta x1
                sta x2                  ;high bytes of x coordinates are 0 (x vertexes are 8 bit)        
                
                
                ldy #$00
                sta draw_count 
                
                lda vex, y
                sta x1+1
                lda vey, y 
                sta y1 
                
                iny 
                inc draw_count 
                
                lda vex, y
                sta x2+1 
                lda vey, y
                sta y2 
                
                jsr line_subroutine     ;line (vx(0), vy(0) - vx(1) ,vy(1)) 
                
                
                ldy draw_count 
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                iny 
                inc draw_count 
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                
                jsr line_subroutine     ;line (vx(1), vy(1) - vx(2), vy(2)) 
                
                ldy draw_count 
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                iny 
                inc draw_count 
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(2), vy(2) - vx(3), vy(3)) 
                
                ldy draw_count 
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                ldy #0
                sty draw_count
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(3), vy(3) - vx(1), vy(1)) 
                
                ldy #4
                sty draw_count
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                iny 
                inc draw_count 
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(4), vy(4) - vx(5), vy(5)) 
                
                ldy draw_count 
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                iny 
                inc draw_count 
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(5), vy(5) - vx(6), vy(6)) 
                
                ldy draw_count 
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                iny 
                inc draw_count 
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(6), vy(6) - vx(7), vy(7)) 
                
                ldy draw_count 
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                ldy #04
                sty draw_count 
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(7), vy(7) - vx(4), vy(4)) 
                
                ldy #00
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                ldy #4
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(0), vy(0) - vx(4), vy(4)) 
                
                ldy #03
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                ldy #7
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(3), vy(3) - vx(7), vy(7)) 
                
                ldy #01
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                ldy #5
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(1), vy(1) - vx(5), vy(5)) 
                
                ldy #02
                
                lda vex, y 
                sta x1+1
               
                lda vey, y
                sta y1 
                
                
                ldy #6
                
                lda vex, y
                sta x2+1
                lda vey, y 
                sta y2 
                
                jsr line_subroutine     ;line (vx(2), vy(2) - vx(6), vy(6))

                ; cube drawn
                
                lda switch_flag
                bne screen2_active
                
                jsr alt_mem 

                jmp skip_alt_mem
                
screen2_active  jsr pref_mem  
                
                
skip_alt_mem

                lda switch_flag
                eor #$01
                sta switch_flag         ;switchs flag for double buffering 
                
;key_read_loop   jsr $ffe4
;                beq key_read_loop
                
                
                
                inc rx
                
                lda rx 
                cmp #63 
                bne jump_cube_loop 
                jmp skip_jump_cube_loop
jump_cube_loop
                jmp cube_loop
                
skip_jump_cube_loop

                lda #$00
                sta rx 
                jmp cube_loop 
                
                
                lda	#15
		sta	$d020

spacechk 	lda 	$dc01 
                cmp 	#$ef 
                bne 	spacechk 

                lda	#$9b
                sta	$d011

                lda	#4
                sta	648

                lda	#21
                sta	$d018
                

                lda	#151
                sta	$dd00			;default vic-ii bank

                lda	#147
                jsr	$ffd2

                lda	#15
                sta	$286

                lda	#00
                sta	198
				

		rts
				
				
				
line_subroutine	

; computes deltax, deltay, decides what routine to be used


                ;lda x1
                ;cmp x2
                ;bcc compute_delta_x2_x1
                ;bne compute_delta_x1_x2                ;high bytes unused
                lda x1+1
                cmp x2+1
                bcc compute_delta_x2_x1			;compares x1 and x2 
				
compute_delta_x1_x2
		
                sec
                lda x1+1
                sbc x2+1
                sta delta_x+1
                ;lda x1
                ;sbc x2
                ;sta delta_x				;delta_x = x1-x2
                
                lda #$01
                sta x_n					;delta_x negative

                jmp skip_compute_delta_x2_x1

compute_delta_x2_x1
                sec
                lda x2+1
                sbc x1+1
                sta delta_x+1
                ;lda x2
                ;sbc x1 
                ;sta delta_x				;delta_x = x2-x1
                
                lda #$00
                sta x_n					;delta_x positive

skip_compute_delta_x2_x1

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
				
compute_delta_y2_y1
				
                sec
                lda y2
                sbc y1
                sta delta_y				;delta_y = y2 - y1

                lda #$00
                sta y_n					;delta_y positive
				
skip_compute_delta_y2_y1
			
				
                ;lda delta_x 
                ;bne jump_110				;if high byte delta_x <> 0 then delta_x > delta_y
                                                        ;high bytes unused 
                lda delta_x+1
                cmp delta_y 
                bcc jump_170			        ;if delta_x+1 < delta_y use routine 170
                
jump_110	jsr line_110			        ;else use routine 110
		
		jmp skip_jump_170
				
jump_170	jsr line_170
				
								
skip_jump_170	

		rts
				


;subroutine: fast line 

line_110 

		;based on v1.3 SLJ 7/2/94
                ;x is only 8 bit - for the cube program is enough 
                
                lda #$00
                sta x2
                sta x1                                  ;set high bytes to zero
                sta xp 
                sta accumulator                         ;zeroes accumulator for line drawing 
                
                lda     x2+1 
                sta     limit
                
                lda     x_n 
                bne     dec_limit
                
                inc     limit 
                jmp     skip_dec_limit 
                
dec_limit       dec     limit 
                
skip_dec_limit  sec
                LDA	accumulator              
                SBC     delta_x+1 
                sta     accumulator
                
LOOPL           jsr     plot 
                               
LOOPLremoved    lda     x_n 
                bne     dec_x                           ;checks for delta_x sign  

                INC     x1+1	                        ;Step in x
                jmp     skip_dec_x 
                
dec_x           DEC     x1+1 

skip_dec_x      clc
                lda     accumulator 
                ADC	delta_y	                        ;Add DY
                sta     accumulator 
                BCC     NOPE	                        ;Time to step in y?
                
                lda     y_n
                bne     dec_y
                
                INC	y1	                        ;Step in y
                
                jmp     skip_dec_y
                
dec_y           dec     y1 
                
skip_dec_y      
                
                SEC 
                LDA     accumulator 
                SBC	delta_x+1	                ;Reset counter
                sta     accumulator 
                
NOPE            

                
                lda     x1+1
                cmp     limit 	                        ;At the endpoint yet?
                bne	LOOPL                            
                
                RTS
                
                
;subroutine: fast line for dy > dx 

line_170 

		;based on v1.3 SLJ 7/2/94
                ;x is only 8 bit - for the cube program is enough 
                
                lda #$00
                sta x2
                sta x1                                   ;set high bytes to zero
                sta xp 
                sta accumulator                         ;zeroes accumulator for line drawing 
                
                lda     y2 
                sta     limit
                
                lda     y_n 
                bne     dec_limit2
                
                inc     limit 
                jmp     skip_dec_limit2 
                
dec_limit2      dec     limit 
                
skip_dec_limit2
                
                sec
                LDA	accumulator              
                SBC     delta_y
                sta     accumulator
                
LOOPL2          jsr     plot 
                
               
LOOPL2removed   lda     y_n 
                bne     dec_y2                          ;checks for delta_x sign  

                INC     y1	                        ;Step in y
                jmp     skip_dec_y2 
                
dec_y2          DEC     y1 

skip_dec_y2     clc
                lda     accumulator 
                ADC	delta_x+1	                ;Add DX
                sta     accumulator 
                BCC     NOPE2	                        ;Time to step in x?
                
                lda     x_n
                bne     dec_x2
                
                INC	x1+1	                        ;Step in x
                
                jmp     skip_dec_x2
                
dec_x2          dec     x1+1 
                
skip_dec_x2     
                SEC 
                LDA     accumulator 
                SBC	delta_y 	                ;Reset counter
                sta     accumulator 
                
NOPE2           

                ;jsr     plot		                ;Plot the point
                lda     y1
                cmp     limit      	                ;At the endpoint yet?
                bne	LOOPL2
                
                RTS
                
; storage location for fast line subroutine 


accumulator     byte    0
limit           byte    0		
			


;subroutine: plot a point (codebase64.org)

plot

		
                ;bmpscreen = start of bitmap screen
                ;byteaddr = address of the byte where the point to plot lies
                
                

                ldy y1
                ldx x1+1
                lda #>xtablehigh
                sta XTBmdf+2
                lda x1
                beq skipadj
                                        
                lda #>(xtablehigh + $ff)		;added brackets, otherwise it won't work
                sta XTBmdf+2		
skipadj:

                lda ytablelow,y
                clc
                adc xtablelow,x
                sta byteaddr

                lda ytablehigh,y
XTBmdf:
                adc xtablehigh,x
                sta byteaddr+1
                
                lda switch_flag
                beq plot_24576 

                lda byteaddr
                clc 
                adc actual_screen+3
                sta byteaddr
                
                lda byteaddr+1
                clc 
                adc actual_screen+2
                sta byteaddr+1
                
                jmp skip_plot_24576 
                
plot_24576      lda byteaddr
                clc
                adc actual_screen+1
                sta byteaddr

                lda byteaddr+1
                adc actual_screen
                sta byteaddr+1

skip_plot_24576 
                ldy #$00
                lda (byteaddr),y
                ora bitable,x
                sta (byteaddr),y
                                        

		rts
                
                
; clear bitmap screen

clear_screen2
		
		ldy	#32
		
loopbmp		ldx	#$00
		lda	#$00            ;filling value 

mod1		sta	bmpscreen,x
		inx
		cpx	#250
		bne	mod1

		clc
		lda	mod1+1
		adc	#250
		sta	mod1+1
		lda	mod1+2
		adc	#00
		sta	mod1+2
		
		dey
		bne	loopbmp
                
                lda     #<bmpscreen
                sta     mod1+1
                lda     #>bmpscreen
                sta     mod1+2
		
		
		rts
                
; clear bitmap screen

clear_screen1
		
		ldy	#32
		
loopbmpbis      ldx	#$00
		lda	#$00            ;filling value 

mod1bis		sta	bmpscreen2,x
		inx
		cpx	#250
		bne	mod1bis

		clc
		lda	mod1bis+1
		adc	#250
		sta	mod1bis+1
		lda	mod1bis+2
		adc	#00
		sta	mod1bis+2
		
		dey
		bne	loopbmpbis
                
                lda     #<bmpscreen2
                sta     mod1bis+1
                lda     #>bmpscreen2
                sta     mod1bis+2
		
		
		rts
                
                
;subroutine: clear part of bmp screen

clear_part2     ;8192

 

                ldx #80
                
                lda #$00
clear_part_loop sta bmpscreen2+2359,x
                sta bmpscreen2+2359+320,x
                sta bmpscreen2+2359+640,x
                sta bmpscreen2+2359+960,x
                sta bmpscreen2+2359+1280,x
                sta bmpscreen2+2359+1600,x
                sta bmpscreen2+2359+1920,x
                sta bmpscreen2+2359+2240,x
                sta bmpscreen2+2359+2560,x
                sta bmpscreen2+2359+2880,x
                sta bmpscreen2+2359+3200,x
                dex 
                
                bne clear_part_loop
                
                
                rts 
                
clear_part1     ;24576



                ldx #80
                
                lda #$00
clear_part_loopbis
                sta bmpscreen+2359,x
                sta bmpscreen+2359+320,x
                sta bmpscreen+2359+640,x
                sta bmpscreen+2359+960,x
                sta bmpscreen+2359+1280,x
                sta bmpscreen+2359+1600,x
                sta bmpscreen+2359+1920,x
                sta bmpscreen+2359+2240,x
                sta bmpscreen+2359+2560,x
                sta bmpscreen+2359+2880,x
                sta bmpscreen+2359+3200,x
                dex 
                               
                
                bne clear_part_loopbis
                
                
                rts 

      

                
;subroutine: signed divide by offset 64 (prod, prod+1) 

divide_prod_signed
                lda #$00
                sta n_flag_divs
                
                lda prod
                bpl skip_comp_divide_signed2    
                
                sec 
                lda #$00
                sbc prod+1 
                sta prod+1 
                lda #$00
                sbc prod
                sta prod                ;takes complement of product 

                lda #$01
                sta n_flag_divs         ;quotient will be negative 
                
skip_comp_divide_signed2
                
                
                
                lda     prod+1
                sta     $fe             ;shift = $fe, holds bits to recover
                lda     prod 
                sta     prod+1
                lda     #$00
                sta     prod            ;/256
                
                asl     $fe
                rol     prod+1
                rol     prod            ;*2 => /256 * 2 = /128
                asl     $fe
                rol     prod+1
                rol     prod            ;*2 => /128 * 2 = /64
                
                                        ;a bit faster than using lsr and ror instructions 
                
                lda n_flag_divs 
                bne comp_quotient2       ;if 8 bit result must be negative ,take complement 
                
                rts 
                
comp_quotient2  
                lda #$00
                sbc prod+1
                sta prod+1
                
                rts 
                
;subroutine: signed divide by offset 64 (multiplier8, sum8) 

divide_signed
                lda #$00
                sta n_flag_divs
                
                lda multiplier8
                bpl skip_comp_divide_signed
                
                sec 
                lda #$00
                sbc sum8
                sta sum8
                lda #$00
                sbc multiplier8
                sta multiplier8         ;takes complement of product 

                lda #$01
                sta n_flag_divs         ;quotient will be negative 
                
skip_comp_divide_signed

                
                 
                lda     sum8
                sta     $fe             ;shift = $fe, holds bits to recover
                lda     multiplier8
                sta     sum8
                lda     #$00
                sta     multiplier8     ;/256
                
                asl     $fe
                rol     sum8
                rol     multiplier8       ;*2 => /256 * 2 = /128
                asl     $fe
                rol     sum8
                rol     multiplier8       ;*2 => /128 * 2 = /64

                
                lda n_flag_divs 
                bne comp_quotient       ;if 8 bit result must be negative ,take complement 
                
                rts 
                
comp_quotient   sec
                lda #$00
                sbc sum8
                sta sum8
                
                rts 
                
                
;subroutine: signed 8 bit multiply (used for rotations and projections)

                
multiply_ab8	lda	#$00
		sta	sum8
                
                sta     multiplicand_sign8
                                        ;multiplicand8 sign positive
                sta     multiplier_sign8 ;multiplier8 sign positive

		ldx	#8		;number of bits
                
                lda     multiplicand8    ;checks sign on high byte
                bpl     skip_multiplicand_comp8
                
                sec
                
                lda     #<256
                sbc     multiplicand8
                sta     multiplicand8  ;takes complement of multiplicand8 
                
                inc     multiplicand_sign8 
                                        ;multiplicand8 sign set to negative
                
skip_multiplicand_comp8

                lda     multiplier8
                bpl     loop8            ;checks sign on high byte
                
                sec
                
                lda     #<256
                sbc     multiplier8
                sta     multiplier8      ;takes complement of multiplier8 
                
                                
                inc     multiplier_sign8 
                                        ;multiplier8 sign set to negative


; fast multiply 

loop8

                
                lda #>square_low
                sta mod12+2
                lda #>square_high
                sta mod22+2

                clc
                lda multiplicand8
                adc multiplier8
                bcc skip_inc
                
                inc mod12+2
                inc mod22+2
                
skip_inc        tax             
                
                sec
                lda multiplicand8
                sbc multiplier8             
                bcs no_diff_fix
                
                sec
                lda multiplier8
                sbc multiplicand8
                
no_diff_fix    
                tay
                              
                sec
mod12           lda square_low,x 
                sbc square_low,y
                sta sum8
                
                
mod22           lda square_high, x
                sbc square_high, y
                sta multiplier8
                
                
                
                                        ;multiplier8 is high byte, sum8 is low byte 
                  
                
                ; sign of product evaluation
                
                lda multiplicand_sign8
                eor multiplier_sign8         
                
                
                beq skip_product_complement8 
                                        ;if product is positive, skip product complement
                
                sec
                lda #< 65536
                sbc sum8
                sta sum8
                lda #> 65536
                sbc multiplier8
                sta multiplier8         ;takes 2 complement of product (16 bit)
              
                

skip_product_complement8
		rts
                

                ;subroutine: bitmap memory from 8192, screen memory from 1024, standard 16k bank 
                
pref_mem 

raster2         lda     53265
                bpl     raster2 
                
                
		ldy	#28
		sty	$d018		;bitmap base 8192

		
                
                lda     $d018
                and     #15
                ora     #16
                sta     $d018           ;default video screen memory (1024) 
                
                lda	#$17
		sta	$dd00		;default vic-ii bank
                
                rts

                
                ;subroutine: bitmap memory from 24576, screen memory from 23552 
alt_mem                 
                
raster1         lda     53265
                bpl     raster1
                
		lda 	$d018
		and	#15
		ora	#112
		sta	$d018		;matrix from 16384+7168=23552

		lda	$d018
		and	#240
		ora	#8
		sta	$d018		;bmp base from 16384+8192 = 24576
                
                lda	$dd00		;CIA-2 bank 1 for VIC
		and	#252
		ora	#2
		sta	$dd00
                
                rts 
                

; storage locations for draw cube 

rx              byte    0
c               byte    0
s               byte    0
temp_y          byte    0
temp_x          byte    0
prod            byte    0,0
point_index     byte    0
draw_count      byte    0

n_flag_divs     byte    0
actual_screen   byte    0,0,0,0

                
                
                ;storage locations for 8 bit multiply


multiplicand_sign8
                byte    0
multiplier_sign8 
                byte    0

multiplicand8	byte	0
multiplier8	byte	0               ;high byte of product
sum8		byte	0               ;low byte of product                  	
	
;storage locations for line subroutine 

x1			byte	0,0
y1			byte	0
x2			byte	0,0
y2			byte	0

delta_x			byte	0,0
delta_y			byte	0
to_mult			byte	0,0,0

x_n			byte	0
y_n			byte	0




		
;storage locations for plot routine


xp		byte	0,0
yp		byte	0
bit_table	byte	128,64,32,16,8,4,2,1
temp		byte	0   	
temp2		byte	0,0 
byteaddr_y	byte	0,0
yp_old		byte	0	
xp_old		byte	0,0





;storage locations for vector routine

;side = 50 - half side = 25 (231 = -25, +25)

;starting vertexes coordinates in two's complement form


x_component     byte    231,231,025,025,231,231,025,025
y_component     byte    231,025,025,231,231,025,025,231
z_component     byte    231,231,231,231,025,025,025,025

;working coordinates

xd_component    byte    0,0,0,0,0,0,0,0
yd_component    byte    0,0,0,0,0,0,0,0
zd_component    byte    0,0,0,0,0,0,0,0 

switch_flag     byte    1       ;stars from 2   

vex             byte    0,0,0,0,0,0,0,0
vey             byte    0,0,0,0,0,0,0,0                           

  
cos_tables
                byte    63 , 63 , 62 , 61 , 58 , 56 , 52 , 48 
                byte    44 , 39 , 34 , 29 , 23 , 17 , 10 , 4 
                byte    254 , 247 , 241 , 235 , 229 , 223 , 218
                byte    213 , 208 , 204 , 201 , 198 , 195 , 193
                byte    192 , 192 , 192 , 192 , 194 , 196 
                byte    198 , 201 , 205 , 209 , 214 , 219 , 224
                byte    230 , 236 , 242 , 248 , 255 , 5 , 11 
                byte    18 , 24 , 29 , 35 , 40 , 45 , 49 , 53 
                byte    56 , 59 , 61 , 62 , 63 


sin_tables      


                byte    0 , 6 , 12 , 18 , 24 , 30 , 36 , 41 , 45
                byte    50 , 53 , 57 , 59 , 61 , 63 , 63 , 63
                byte    63 , 62 , 60 , 58 , 55 , 51 , 47 , 43 
                byte    38 , 32 , 27 , 21 , 15 , 9 , 2 , 252
                byte    245 , 239 , 233 , 227 , 222 , 216 , 211
                byte    207 , 203 , 200 , 197 , 195 , 193 
                byte    192 , 192 , 192 , 193 , 194 , 196 , 199
                byte    202 , 206 , 210 , 215 , 220 , 226 , 232
                byte    238 , 244 , 250 


projpos

                ;all values from 0 to 255 are computed, though not necessary 
                byte  64 , 63 , 63 , 63 , 62 , 62
                byte  62 , 61 , 61 , 61 , 60 , 60
                byte  60 , 60 , 59 , 59 , 59 , 58
                byte  58 , 58 , 58 , 57 , 57 , 57
                byte  57 , 56 , 56 , 56 , 56 , 55
                byte  55 , 55 , 55 , 54 , 54 , 54
                byte  54 , 54 , 53 , 53 , 53 , 53
                byte  52 , 52 , 52 , 52 , 52 , 51
                byte  51 , 51 , 51 , 50 , 50 , 50
                byte  50 , 50 , 50 , 49 , 49 , 49
                byte  49 , 49 , 48 , 48 , 48 , 48
                byte  48 , 47 , 47 , 47 , 47 , 47
                byte  47 , 46 , 46 , 46 , 46 , 46
                byte  46 , 45 , 45 , 45 , 45 , 45
                byte  45 , 44 , 44 , 44 , 44 , 44
                byte  44 , 43 , 43 , 43 , 43 , 43
                byte  43 , 43 , 42 , 42 , 42 , 42
                byte  42 , 42 , 42 , 41 , 41 , 41
                byte  41 , 41 , 41 , 41 , 41 , 40
                byte  40 , 40 , 40 , 40 , 40 , 40
                ;**********************

                byte  40 , 39 , 39 , 39 , 39 , 39
                byte  39 , 39 , 39 , 38 , 38 , 38
                byte  38 , 38 , 38 , 38 , 38 , 37
                byte  37 , 37 , 37 , 37 , 37 , 37
                byte  37 , 37 , 36 , 36 , 36 , 36
                byte  36 , 36 , 36 , 36 , 36 , 36
                byte  35 , 35 , 35 , 35 , 35 , 35
                byte  35 , 35 , 35 , 35 , 34 , 34
                byte  34 , 34 , 34 , 34 , 34 , 34
                byte  34 , 34 , 34 , 33 , 33 , 33
                byte  33 , 33 , 33 , 33 , 33 , 33
                byte  33 , 33 , 32 , 32 , 32 , 32
                byte  32 , 32 , 32 , 32 , 32 , 32
                byte  32 , 32 , 32 , 31 , 31 , 31
                byte  31 , 31 , 31 , 31 , 31 , 31
                byte  31 , 31 , 31 , 30 , 30 , 30
                byte  30 , 30 , 30 , 30 , 30 , 30
                byte  30 , 30 , 30 , 30 , 30 , 29
                byte  29 , 29 , 29 , 29 , 29 , 29
                byte  29 , 29 , 29 , 29 , 29 , 29
                ;**********************

                ;**********************
                byte  29 , 29 , 28 , 28 , 28 , 28
                byte  28 , 28 , 28 , 28 , 28 , 28
                byte  28 , 28 , 28 , 28


projneg         ;only values indexed from 0 to 99 to stay on the 8 bit signed positive limit
                ;those values should be enough (z check may be included in the code)




                byte 64 , 64 , 64 , 64 , 65
                byte 65 , 65 , 66 , 66 , 67
                byte 67 , 67 , 68 , 68 , 68
                byte 69 , 69 , 69 , 70 , 70
                byte 71 , 71 , 71 , 72 , 72
                byte 73 , 73 , 73 , 74 , 74
                byte 75 , 75 , 76 , 76 , 77
                byte 77 , 78 , 78 , 79 , 79
                byte 80 , 80 , 81 , 81 , 82
                byte 82 , 83 , 83 , 84 , 84
                byte 85 , 85 , 86 , 87 , 87
                byte 88 , 88 , 89 , 90 , 90
                byte 91 , 92 , 92 , 93 , 94
                byte 94 , 95 , 96 , 96 , 97
                byte 98 , 99 , 100 , 100 , 101
                byte 102 , 103 , 104 , 104 , 105
                byte 106 , 107 , 108 , 109 , 110
                byte 111 , 112 , 113 , 114 , 115
                byte 116 , 117 , 118 , 119 , 120
                byte 121 , 123 , 124 , 125 , 126        
                ;**********************
                

              
                
                
;******************** PLOT TABLE *********************

ytablelow
byte 0,1,2,3,4,5,6,7
byte 64,65,66,67,68,69,70,71
byte 128,129,130,131,132,133,134,135
byte 192,193,194,195,196,197,198,199
byte 0,1,2,3,4,5,6,7
byte 64,65,66,67,68,69,70,71
byte 128,129,130,131,132,133,134,135
byte 192,193,194,195,196,197,198,199
byte 0,1,2,3,4,5,6,7
byte 64,65,66,67,68,69,70,71
byte 128,129,130,131,132,133,134,135
byte 192,193,194,195,196,197,198,199
byte 0,1,2,3,4,5,6,7
byte 64,65,66,67,68,69,70,71
byte 128,129,130,131,132,133,134,135
byte 192,193,194,195,196,197,198,199
byte 0,1,2,3,4,5,6,7
byte 64,65,66,67,68,69,70,71
byte 128,129,130,131,132,133,134,135
byte 192,193,194,195,196,197,198,199
byte 0,1,2,3,4,5,6,7
byte 64,65,66,67,68,69,70,71
byte 128,129,130,131,132,133,134,135
;*********************
byte 192,193,194,195,196,197,198,199
byte 0,1,2,3,4,5,6,7

ytablehigh
byte 0,0,0,0,0,0,0,0
byte 1,1,1,1,1,1,1,1
byte 2,2,2,2,2,2,2,2
byte 3,3,3,3,3,3,3,3
byte 5,5,5,5,5,5,5,5
byte 6,6,6,6,6,6,6,6
byte 7,7,7,7,7,7,7,7
byte 8,8,8,8,8,8,8,8
byte 10,10,10,10,10,10,10,10
byte 11,11,11,11,11,11,11,11
byte 12,12,12,12,12,12,12,12
byte 13,13,13,13,13,13,13,13
byte 15,15,15,15,15,15,15,15
byte 16,16,16,16,16,16,16,16
byte 17,17,17,17,17,17,17,17
byte 18,18,18,18,18,18,18,18
byte 20,20,20,20,20,20,20,20
byte 21,21,21,21,21,21,21,21
byte 22,22,22,22,22,22,22,22
;*********************
byte 23,23,23,23,23,23,23,23
byte 25,25,25,25,25,25,25,25
byte 26,26,26,26,26,26,26,26
byte 27,27,27,27,27,27,27,27
byte 28,28,28,28,28,28,28,28
byte 30,30,30,30,30,30,30,30

xtablelow
byte 0,0,0,0,0,0,0,0
byte 8,8,8,8,8,8,8,8
byte 16,16,16,16,16,16,16,16
byte 24,24,24,24,24,24,24,24
byte 32,32,32,32,32,32,32,32
byte 40,40,40,40,40,40,40,40
byte 48,48,48,48,48,48,48,48
byte 56,56,56,56,56,56,56,56
byte 64,64,64,64,64,64,64,64
byte 72,72,72,72,72,72,72,72
byte 80,80,80,80,80,80,80,80
byte 88,88,88,88,88,88,88,88
byte 96,96,96,96,96,96,96,96
byte 104,104,104,104,104,104,104,104
byte 112,112,112,112,112,112,112,112
;*********************
byte 120,120,120,120,120,120,120,120
byte 128,128,128,128,128,128,128,128
byte 136,136,136,136,136,136,136,136
byte 144,144,144,144,144,144,144,144
byte 152,152,152,152,152,152,152,152
byte 160,160,160,160,160,160,160,160
byte 168,168,168,168,168,168,168,168
byte 176,176,176,176,176,176,176,176
byte 184,184,184,184,184,184,184,184
byte 192,192,192,192,192,192,192,192
byte 200,200,200,200,200,200,200,200
byte 208,208,208,208,208,208,208,208
byte 216,216,216,216,216,216,216,216
byte 224,224,224,224,224,224,224,224
byte 232,232,232,232,232,232,232,232
byte 240,240,240,240,240,240,240,240
byte 248,248,248,248,248,248,248,248
byte 0,0,0,0,0,0,0,0
byte 8,8,8,8,8,8,8,8
byte 16,16,16,16,16,16,16,16
byte 24,24,24,24,24,24,24,24
byte 32,32,32,32,32,32,32,32
byte 40,40,40,40,40,40,40,40
;*********************
byte 48,48,48,48,48,48,48,48
byte 56,56,56,56,56,56,56,56

xtablehigh
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
;*********************
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 0,0,0,0,0,0,0,0
byte 1,1,1,1,1,1,1,1
byte 1,1,1,1,1,1,1,1
byte 1,1,1,1,1,1,1,1
byte 1,1,1,1,1,1,1,1
byte 1,1,1,1,1,1,1,1
byte 1,1,1,1,1,1,1,1
byte 1,1,1,1,1,1,1,1
byte 1,1,1,1,1,1,1,1

bitable
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
;*********************
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1

byte 128,64,32,16,8,4,2,1	;those values from here should not be necessary, but leaved in place for safety
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1
byte 128,64,32,16,8,4,2,1


square_high

;squares 0...510 high bytes
byte  0 , 0 , 0 , 0 , 0
byte  0 , 0 , 0 , 0 , 0
byte  0 , 0 , 0 , 0 , 0
byte  0 , 0 , 0 , 0 , 0
byte  0 , 0 , 0 , 0 , 0
byte  0 , 0 , 0 , 0 , 0
byte  0 , 0 , 1 , 1 , 1
byte  1 , 1 , 1 , 1 , 1
byte  1 , 1 , 1 , 1 , 1
byte  1 , 2 , 2 , 2 , 2
byte  2 , 2 , 2 , 2 , 2
byte  2 , 3 , 3 , 3 , 3
byte  3 , 3 , 3 , 3 , 4
byte  4 , 4 , 4 , 4 , 4
byte  4 , 4 , 5 , 5 , 5
byte  5 , 5 , 5 , 5 , 6
byte  6 , 6 , 6 , 6 , 6
byte  7 , 7 , 7 , 7 , 7
byte  7 , 8 , 8 , 8 , 8
byte  8 , 9 , 9 , 9 , 9
;***************************


byte  9 , 9 , 10 , 10 , 10
byte  10 , 10 , 11 , 11 , 11
byte  11 , 12 , 12 , 12 , 12
byte  12 , 13 , 13 , 13 , 13
byte  14 , 14 , 14 , 14 , 15
byte  15 , 15 , 15 , 16 , 16
byte  16 , 16 , 17 , 17 , 17
byte  17 , 18 , 18 , 18 , 18
byte  19 , 19 , 19 , 19 , 20
byte  20 , 20 , 21 , 21 , 21
byte  21 , 22 , 22 , 22 , 23
byte  23 , 23 , 24 , 24 , 24
byte  25 , 25 , 25 , 25 , 26
byte  26 , 26 , 27 , 27 , 27
byte  28 , 28 , 28 , 29 , 29
byte  29 , 30 , 30 , 30 , 31
byte  31 , 31 , 32 , 32 , 33
byte  33 , 33 , 34 , 34 , 34
byte  35 , 35 , 36 , 36 , 36
byte  37 , 37 , 37 , 38 , 38
;***************************


byte  39 , 39 , 39 , 40 , 40
byte  41 , 41 , 41 , 42 , 42
byte  43 , 43 , 43 , 44 , 44
byte  45 , 45 , 45 , 46 , 46
byte  47 , 47 , 48 , 48 , 49
byte  49 , 49 , 50 , 50 , 51
byte  51 , 52 , 52 , 53 , 53
byte  53 , 54 , 54 , 55 , 55
byte  56 , 56 , 57 , 57 , 58
byte  58 , 59 , 59 , 60 , 60
byte  61 , 61 , 62 , 62 , 63
byte  63 , 64 , 64 , 65 , 65
byte  66 , 66 , 67 , 67 , 68
byte  68 , 69 , 69 , 70 , 70
byte  71 , 71 , 72 , 72 , 73
byte  73 , 74 , 74 , 75 , 76
byte  76 , 77 , 77 , 78 , 78
byte  79 , 79 , 80 , 81 , 81
byte  82 , 82 , 83 , 83 , 84
byte  84 , 85 , 86 , 86 , 87
;***************************


byte  87 , 88 , 89 , 89 , 90
byte  90 , 91 , 92 , 92 , 93
byte  93 , 94 , 95 , 95 , 96
byte  96 , 97 , 98 , 98 , 99
byte  100 , 100 , 101 , 101 , 102
byte  103 , 103 , 104 , 105 , 105
byte  106 , 106 , 107 , 108 , 108
byte  109 , 110 , 110 , 111 , 112
byte  112 , 113 , 114 , 114 , 115
byte  116 , 116 , 117 , 118 , 118
byte  119 , 120 , 121 , 121 , 122
byte  123 , 123 , 124 , 125 , 125
byte  126 , 127 , 127 , 128 , 129
byte  130 , 130 , 131 , 132 , 132
byte  133 , 134 , 135 , 135 , 136
byte  137 , 138 , 138 , 139 , 140
byte  141 , 141 , 142 , 143 , 144
byte  144 , 145 , 146 , 147 , 147
byte  148 , 149 , 150 , 150 , 151
byte  152 , 153 , 153 , 154 , 155
;***************************


byte  156 , 157 , 157 , 158 , 159
byte  160 , 160 , 161 , 162 , 163
byte  164 , 164 , 165 , 166 , 167
byte  168 , 169 , 169 , 170 , 171
byte  172 , 173 , 173 , 174 , 175
byte  176 , 177 , 178 , 178 , 179
byte  180 , 181 , 182 , 183 , 183
byte  184 , 185 , 186 , 187 , 188
byte  189 , 189 , 190 , 191 , 192
byte  193 , 194 , 195 , 196 , 196
byte  197 , 198 , 199 , 200 , 201
byte  202 , 203 , 203 , 204 , 205
byte  206 , 207 , 208 , 209 , 210
byte  211 , 212 , 212 , 213 , 214
byte  215 , 216 , 217 , 218 , 219
byte  220 , 221 , 222 , 223 , 224
byte  225 , 225 , 226 , 227 , 228
byte  229 , 230 , 231 , 232 , 233
byte  234 , 235 , 236 , 237 , 238
byte  239 , 240 , 241 , 242 , 243
;***************************


byte  244 , 245 , 246 , 247 , 248
byte  249 , 250 , 251 , 252 , 253
byte  254 

;***************************



;***************************

square_low

;squares 0...510 low bytes
byte  0 , 0 , 1 , 2 , 4
byte  6 , 9 , 12 , 16 , 20
byte  25 , 30 , 36 , 42 , 49
byte  56 , 64 , 72 , 81 , 90
byte  100 , 110 , 121 , 132 , 144
byte  156 , 169 , 182 , 196 , 210
byte  225 , 240 , 0 , 16 , 33
byte  50 , 68 , 86 , 105 , 124
byte  144 , 164 , 185 , 206 , 228
byte  250 , 17 , 40 , 64 , 88
byte  113 , 138 , 164 , 190 , 217
byte  244 , 16 , 44 , 73 , 102
byte  132 , 162 , 193 , 224 , 0
byte  32 , 65 , 98 , 132 , 166
byte  201 , 236 , 16 , 52 , 89
byte  126 , 164 , 202 , 241 , 24
byte  64 , 104 , 145 , 186 , 228
byte  14 , 57 , 100 , 144 , 188
byte  233 , 22 , 68 , 114 , 161
byte  208 , 0 , 48 , 97 , 146
;***************************



byte  196 , 246 , 41 , 92 , 144
byte  196 , 249 , 46 , 100 , 154
byte  209 , 8 , 64 , 120 , 177
byte  234 , 36 , 94 , 153 , 212
byte  16 , 76 , 137 , 198 , 4
byte  66 , 129 , 192 , 0 , 64
byte  129 , 194 , 4 , 70 , 137
byte  204 , 16 , 84 , 153 , 222
byte  36 , 106 , 177 , 248 , 64
byte  136 , 209 , 26 , 100 , 174
byte  249 , 68 , 144 , 220 , 41
byte  118 , 196 , 18 , 97 , 176
byte  0 , 80 , 161 , 242 , 68
byte  150 , 233 , 60 , 144 , 228
byte  57 , 142 , 228 , 58 , 145
byte  232 , 64 , 152 , 241 , 74
byte  164 , 254 , 89 , 180 , 16
byte  108 , 201 , 38 , 132 , 226
byte  65 , 160 , 0 , 96 , 193
byte  34 , 132 , 230 , 73 , 172
;***************************



byte  16 , 116 , 217 , 62 , 164
byte  10 , 113 , 216 , 64 , 168
byte  17 , 122 , 228 , 78 , 185
byte  36 , 144 , 252 , 105 , 214
byte  68 , 178 , 33 , 144 , 0
byte  112 , 225 , 82 , 196 , 54
byte  169 , 28 , 144 , 4 , 121
byte  238 , 100 , 218 , 81 , 200
byte  64 , 184 , 49 , 170 , 36
byte  158 , 25 , 148 , 16 , 140
byte  9 , 134 , 4 , 130 , 1
byte  128 , 0 , 128 , 1 , 130
byte  4 , 134 , 9 , 140 , 16
byte  148 , 25 , 158 , 36 , 170
byte  49 , 184 , 64 , 200 , 81
byte  218 , 100 , 238 , 121 , 4
byte  144 , 28 , 169 , 54 , 196
byte  82 , 225 , 112 , 0 , 144
byte  33 , 178 , 68 , 214 , 105
byte  252 , 144 , 36 , 185 , 78
;***************************



byte  228 , 122 , 17 , 168 , 64
byte  216 , 113 , 10 , 164 , 62
byte  217 , 116 , 16 , 172 , 73
byte  230 , 132 , 34 , 193 , 96
byte  0 , 160 , 65 , 226 , 132
byte  38 , 201 , 108 , 16 , 180
byte  89 , 254 , 164 , 74 , 241
byte  152 , 64 , 232 , 145 , 58
byte  228 , 142 , 57 , 228 , 144
byte  60 , 233 , 150 , 68 , 242
byte  161 , 80 , 0 , 176 , 97
byte  18 , 196 , 118 , 41 , 220
byte  144 , 68 , 249 , 174 , 100
byte  26 , 209 , 136 , 64 , 248
byte  177 , 106 , 36 , 222 , 153
byte  84 , 16 , 204 , 137 , 70
byte  4 , 194 , 129 , 64 , 0
byte  192 , 129 , 66 , 4 , 198
byte  137 , 76 , 16 , 212 , 153
byte  94 , 36 , 234 , 177 , 120
;***************************


byte  64 , 8 , 209 , 154 , 100
byte  46 , 249 , 196 , 144 , 92
byte  41 , 246 , 196 , 146 , 97
byte  48 , 0 , 208 , 161 , 114
byte  68 , 22 , 233 , 188 , 144
byte  100 , 57 , 14 , 228 , 186
byte  145 , 104 , 64 , 24 , 241
byte  202 , 164 , 126 , 89 , 52
byte  16 , 236 , 201 , 166 , 132
byte  98 , 65 , 32 , 0 , 224
byte  193 , 162 , 132 , 102 , 73
byte  44 , 16 , 244 , 217 , 190
byte  164 , 138 , 113 , 88 , 64
byte  40 , 17 , 250 , 228 , 206
byte  185 , 164 , 144 , 124 , 105
byte  86 , 68 , 50 , 33 , 16
byte  0 , 240 , 225 , 210 , 196
byte  182 , 169 , 156 , 144 , 132
byte  121 , 110 , 100 , 90 , 81
byte  72 , 64 , 56 , 49 , 42
;***************************



byte  36 , 30 , 25 , 20 , 16
byte  12 , 9 , 6 , 4 , 2
byte  1 


