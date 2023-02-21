; ported from
; https://retro64.altervista.org/blog/an-introduction-to-vector-based-graphics-the-commodore-64-rotating-simple-3d-objects/




.autoimport	on              ; imports C library functions
.forceimport	__STARTUP__ ; imports STARTUP, INIT, ONCE
.export		_main           ; expose mane to the C library
.include        "zeropage.inc"


; macros
BMP0 = $6000   ; starting address of bitmap
BMP1 = $2000

; use 16 bit X
;USE_X16 = 1

; bigger cube
BIGGER = 1

; rotate which axis.  Enable 1
;ROTATE_Y = 1
ROTATE_XY = 1 ; BIGGER must be enabled for this one


; zero page aliases
byteaddr := tmp1		; 2 bytes



; global variables
.segment	"DATA"

current_screen:   .res 1       ; flag for double-buffering 
x1:			.res	2
y1:			.res	1
x2:			.res	2
y2:			.res	1
delta_x:	.res	2
delta_y:	.res	1
x_n:		.res	1
y_n:		.res	1

accumulator:     .res	1
limit:           .res	1
xp:		         .res	2
rx:              .res	1
c:               .res	1
s:               .res	1
point_index:     .res	1
draw_count:      .res	1
prod:            .res	2
temp_y:          .res	1
temp_x:          .res	1
temp_z:          .res	1
n_flag_divs:     .res	1
multiplicand_sign8:   .res	1
multiplier_sign8:     .res	1
multiplicand8:   .res	1
multiplier8:     .res	1    ;high byte of product
sum8:            .res	1    ;low byte of product                  	

vex:             .res 8
vey:             .res 8                       

;working coordinates
xd_component:
    .byte    0,0,0,0,0,0,0,0
yd_component:
    .byte    0,0,0,0,0,0,0,0
zd_component:
    .byte    0,0,0,0,0,0,0,0 


.segment	"RODATA"
;starting vertexes coordinates in two's complement form

.ifdef BIGGER

x_component: 
    .byte    221,221,035,035,221,221,035,035
y_component: 
    .byte    221,035,035,221,221,035,035,221
z_component: 
    .byte    221,221,221,221,035,035,035,035

.else

x_component:
    .byte    231,231,025,025,231,231,025,025
y_component:
    .byte    231,025,025,231,231,025,025,231
z_component:
    .byte    231,231,231,231,025,025,025,025

.endif


cos_tables:
    .byte    63 , 63 , 62 , 61 , 58 , 56 , 52 , 48 
    .byte    44 , 39 , 34 , 29 , 23 , 17 , 10 , 4 
    .byte    254 , 247 , 241 , 235 , 229 , 223 , 218
    .byte    213 , 208 , 204 , 201 , 198 , 195 , 193
    .byte    192 , 192 , 192 , 192 , 194 , 196 
    .byte    198 , 201 , 205 , 209 , 214 , 219 , 224
    .byte    230 , 236 , 242 , 248 , 255 , 5 , 11 
    .byte    18 , 24 , 29 , 35 , 40 , 45 , 49 , 53 
    .byte    56 , 59 , 61 , 62 , 63 


sin_tables:
    .byte    0 , 6 , 12 , 18 , 24 , 30 , 36 , 41 , 45
    .byte    50 , 53 , 57 , 59 , 61 , 63 , 63 , 63
    .byte    63 , 62 , 60 , 58 , 55 , 51 , 47 , 43 
    .byte    38 , 32 , 27 , 21 , 15 , 9 , 2 , 252
    .byte    245 , 239 , 233 , 227 , 222 , 216 , 211
    .byte    207 , 203 , 200 , 197 , 195 , 193 
    .byte    192 , 192 , 192 , 193 , 194 , 196 , 199
    .byte    202 , 206 , 210 , 215 , 220 , 226 , 232
    .byte    238 , 244 , 250 


projpos:
;all values from 0 to 255 are computed, though not necessary 
    .byte  64 , 63 , 63 , 63 , 62 , 62
    .byte  62 , 61 , 61 , 61 , 60 , 60
    .byte  60 , 60 , 59 , 59 , 59 , 58
    .byte  58 , 58 , 58 , 57 , 57 , 57
    .byte  57 , 56 , 56 , 56 , 56 , 55
    .byte  55 , 55 , 55 , 54 , 54 , 54
    .byte  54 , 54 , 53 , 53 , 53 , 53
    .byte  52 , 52 , 52 , 52 , 52 , 51
    .byte  51 , 51 , 51 , 50 , 50 , 50
    .byte  50 , 50 , 50 , 49 , 49 , 49
    .byte  49 , 49 , 48 , 48 , 48 , 48
    .byte  48 , 47 , 47 , 47 , 47 , 47
    .byte  47 , 46 , 46 , 46 , 46 , 46
    .byte  46 , 45 , 45 , 45 , 45 , 45
    .byte  45 , 44 , 44 , 44 , 44 , 44
    .byte  44 , 43 , 43 , 43 , 43 , 43
    .byte  43 , 43 , 42 , 42 , 42 , 42
    .byte  42 , 42 , 42 , 41 , 41 , 41
    .byte  41 , 41 , 41 , 41 , 41 , 40
    .byte  40 , 40 , 40 , 40 , 40 , 40
    .byte  40 , 39 , 39 , 39 , 39 , 39
    .byte  39 , 39 , 39 , 38 , 38 , 38
    .byte  38 , 38 , 38 , 38 , 38 , 37
    .byte  37 , 37 , 37 , 37 , 37 , 37
    .byte  37 , 37 , 36 , 36 , 36 , 36
    .byte  36 , 36 , 36 , 36 , 36 , 36
    .byte  35 , 35 , 35 , 35 , 35 , 35
    .byte  35 , 35 , 35 , 35 , 34 , 34
    .byte  34 , 34 , 34 , 34 , 34 , 34
    .byte  34 , 34 , 34 , 33 , 33 , 33
    .byte  33 , 33 , 33 , 33 , 33 , 33
    .byte  33 , 33 , 32 , 32 , 32 , 32
    .byte  32 , 32 , 32 , 32 , 32 , 32
    .byte  32 , 32 , 32 , 31 , 31 , 31
    .byte  31 , 31 , 31 , 31 , 31 , 31
    .byte  31 , 31 , 31 , 30 , 30 , 30
    .byte  30 , 30 , 30 , 30 , 30 , 30
    .byte  30 , 30 , 30 , 30 , 30 , 29
    .byte  29 , 29 , 29 , 29 , 29 , 29
    .byte  29 , 29 , 29 , 29 , 29 , 29
    .byte  29 , 29 , 28 , 28 , 28 , 28
    .byte  28 , 28 , 28 , 28 , 28 , 28
    .byte  28 , 28 , 28 , 28


projneg:
;only values indexed from 0 to 99 to stay on the 8 bit signed positive limit
;those values should be enough (z check may be included in the code)
    .byte 64 , 64 , 64 , 64 , 65
    .byte 65 , 65 , 66 , 66 , 67
    .byte 67 , 67 , 68 , 68 , 68
    .byte 69 , 69 , 69 , 70 , 70
    .byte 71 , 71 , 71 , 72 , 72
    .byte 73 , 73 , 73 , 74 , 74
    .byte 75 , 75 , 76 , 76 , 77
    .byte 77 , 78 , 78 , 79 , 79
    .byte 80 , 80 , 81 , 81 , 82
    .byte 82 , 83 , 83 , 84 , 84
    .byte 85 , 85 , 86 , 87 , 87
    .byte 88 , 88 , 89 , 90 , 90
    .byte 91 , 92 , 92 , 93 , 94
    .byte 94 , 95 , 96 , 96 , 97
    .byte 98 , 99 , 100 , 100 , 101
    .byte 102 , 103 , 104 , 104 , 105
    .byte 106 , 107 , 108 , 109 , 110
    .byte 111 , 112 , 113 , 114 , 115
    .byte 116 , 117 , 118 , 119 , 120
    .byte 121 , 123 , 124 , 125 , 126        


square_high:
;squares 0...510 high bytes
    .byte  0 , 0 , 0 , 0 , 0
    .byte  0 , 0 , 0 , 0 , 0
    .byte  0 , 0 , 0 , 0 , 0
    .byte  0 , 0 , 0 , 0 , 0
    .byte  0 , 0 , 0 , 0 , 0
    .byte  0 , 0 , 0 , 0 , 0
    .byte  0 , 0 , 1 , 1 , 1
    .byte  1 , 1 , 1 , 1 , 1
    .byte  1 , 1 , 1 , 1 , 1
    .byte  1 , 2 , 2 , 2 , 2
    .byte  2 , 2 , 2 , 2 , 2
    .byte  2 , 3 , 3 , 3 , 3
    .byte  3 , 3 , 3 , 3 , 4
    .byte  4 , 4 , 4 , 4 , 4
    .byte  4 , 4 , 5 , 5 , 5
    .byte  5 , 5 , 5 , 5 , 6
    .byte  6 , 6 , 6 , 6 , 6
    .byte  7 , 7 , 7 , 7 , 7
    .byte  7 , 8 , 8 , 8 , 8
    .byte  8 , 9 , 9 , 9 , 9
    .byte  9 , 9 , 10 , 10 , 10
    .byte  10 , 10 , 11 , 11 , 11
    .byte  11 , 12 , 12 , 12 , 12
    .byte  12 , 13 , 13 , 13 , 13
    .byte  14 , 14 , 14 , 14 , 15
    .byte  15 , 15 , 15 , 16 , 16
    .byte  16 , 16 , 17 , 17 , 17
    .byte  17 , 18 , 18 , 18 , 18
    .byte  19 , 19 , 19 , 19 , 20
    .byte  20 , 20 , 21 , 21 , 21
    .byte  21 , 22 , 22 , 22 , 23
    .byte  23 , 23 , 24 , 24 , 24
    .byte  25 , 25 , 25 , 25 , 26
    .byte  26 , 26 , 27 , 27 , 27
    .byte  28 , 28 , 28 , 29 , 29
    .byte  29 , 30 , 30 , 30 , 31
    .byte  31 , 31 , 32 , 32 , 33
    .byte  33 , 33 , 34 , 34 , 34
    .byte  35 , 35 , 36 , 36 , 36
    .byte  37 , 37 , 37 , 38 , 38
    .byte  39 , 39 , 39 , 40 , 40
    .byte  41 , 41 , 41 , 42 , 42
    .byte  43 , 43 , 43 , 44 , 44
    .byte  45 , 45 , 45 , 46 , 46
    .byte  47 , 47 , 48 , 48 , 49
    .byte  49 , 49 , 50 , 50 , 51
    .byte  51 , 52 , 52 , 53 , 53
    .byte  53 , 54 , 54 , 55 , 55
    .byte  56 , 56 , 57 , 57 , 58
    .byte  58 , 59 , 59 , 60 , 60
    .byte  61 , 61 , 62 , 62 , 63
    .byte  63 , 64 , 64 , 65 , 65
    .byte  66 , 66 , 67 , 67 , 68
    .byte  68 , 69 , 69 , 70 , 70
    .byte  71 , 71 , 72 , 72 , 73
    .byte  73 , 74 , 74 , 75 , 76
    .byte  76 , 77 , 77 , 78 , 78
    .byte  79 , 79 , 80 , 81 , 81
    .byte  82 , 82 , 83 , 83 , 84
    .byte  84 , 85 , 86 , 86 , 87
    .byte  87 , 88 , 89 , 89 , 90
    .byte  90 , 91 , 92 , 92 , 93
    .byte  93 , 94 , 95 , 95 , 96
    .byte  96 , 97 , 98 , 98 , 99
    .byte  100 , 100 , 101 , 101 , 102
    .byte  103 , 103 , 104 , 105 , 105
    .byte  106 , 106 , 107 , 108 , 108
    .byte  109 , 110 , 110 , 111 , 112
    .byte  112 , 113 , 114 , 114 , 115
    .byte  116 , 116 , 117 , 118 , 118
    .byte  119 , 120 , 121 , 121 , 122
    .byte  123 , 123 , 124 , 125 , 125
    .byte  126 , 127 , 127 , 128 , 129
    .byte  130 , 130 , 131 , 132 , 132
    .byte  133 , 134 , 135 , 135 , 136
    .byte  137 , 138 , 138 , 139 , 140
    .byte  141 , 141 , 142 , 143 , 144
    .byte  144 , 145 , 146 , 147 , 147
    .byte  148 , 149 , 150 , 150 , 151
    .byte  152 , 153 , 153 , 154 , 155
    .byte  156 , 157 , 157 , 158 , 159
    .byte  160 , 160 , 161 , 162 , 163
    .byte  164 , 164 , 165 , 166 , 167
    .byte  168 , 169 , 169 , 170 , 171
    .byte  172 , 173 , 173 , 174 , 175
    .byte  176 , 177 , 178 , 178 , 179
    .byte  180 , 181 , 182 , 183 , 183
    .byte  184 , 185 , 186 , 187 , 188
    .byte  189 , 189 , 190 , 191 , 192
    .byte  193 , 194 , 195 , 196 , 196
    .byte  197 , 198 , 199 , 200 , 201
    .byte  202 , 203 , 203 , 204 , 205
    .byte  206 , 207 , 208 , 209 , 210
    .byte  211 , 212 , 212 , 213 , 214
    .byte  215 , 216 , 217 , 218 , 219
    .byte  220 , 221 , 222 , 223 , 224
    .byte  225 , 225 , 226 , 227 , 228
    .byte  229 , 230 , 231 , 232 , 233
    .byte  234 , 235 , 236 , 237 , 238
    .byte  239 , 240 , 241 , 242 , 243
    .byte  244 , 245 , 246 , 247 , 248
    .byte  249 , 250 , 251 , 252 , 253
    .byte  254 




;***************************

square_low:
;squares 0...510 low bytes
    .byte  0 , 0 , 1 , 2 , 4
    .byte  6 , 9 , 12 , 16 , 20
    .byte  25 , 30 , 36 , 42 , 49
    .byte  56 , 64 , 72 , 81 , 90
    .byte  100 , 110 , 121 , 132 , 144
    .byte  156 , 169 , 182 , 196 , 210
    .byte  225 , 240 , 0 , 16 , 33
    .byte  50 , 68 , 86 , 105 , 124
    .byte  144 , 164 , 185 , 206 , 228
    .byte  250 , 17 , 40 , 64 , 88
    .byte  113 , 138 , 164 , 190 , 217
    .byte  244 , 16 , 44 , 73 , 102
    .byte  132 , 162 , 193 , 224 , 0
    .byte  32 , 65 , 98 , 132 , 166
    .byte  201 , 236 , 16 , 52 , 89
    .byte  126 , 164 , 202 , 241 , 24
    .byte  64 , 104 , 145 , 186 , 228
    .byte  14 , 57 , 100 , 144 , 188
    .byte  233 , 22 , 68 , 114 , 161
    .byte  208 , 0 , 48 , 97 , 146
    .byte  196 , 246 , 41 , 92 , 144
    .byte  196 , 249 , 46 , 100 , 154
    .byte  209 , 8 , 64 , 120 , 177
    .byte  234 , 36 , 94 , 153 , 212
    .byte  16 , 76 , 137 , 198 , 4
    .byte  66 , 129 , 192 , 0 , 64
    .byte  129 , 194 , 4 , 70 , 137
    .byte  204 , 16 , 84 , 153 , 222
    .byte  36 , 106 , 177 , 248 , 64
    .byte  136 , 209 , 26 , 100 , 174
    .byte  249 , 68 , 144 , 220 , 41
    .byte  118 , 196 , 18 , 97 , 176
    .byte  0 , 80 , 161 , 242 , 68
    .byte  150 , 233 , 60 , 144 , 228
    .byte  57 , 142 , 228 , 58 , 145
    .byte  232 , 64 , 152 , 241 , 74
    .byte  164 , 254 , 89 , 180 , 16
    .byte  108 , 201 , 38 , 132 , 226
    .byte  65 , 160 , 0 , 96 , 193
    .byte  34 , 132 , 230 , 73 , 172
    .byte  16 , 116 , 217 , 62 , 164
    .byte  10 , 113 , 216 , 64 , 168
    .byte  17 , 122 , 228 , 78 , 185
    .byte  36 , 144 , 252 , 105 , 214
    .byte  68 , 178 , 33 , 144 , 0
    .byte  112 , 225 , 82 , 196 , 54
    .byte  169 , 28 , 144 , 4 , 121
    .byte  238 , 100 , 218 , 81 , 200
    .byte  64 , 184 , 49 , 170 , 36
    .byte  158 , 25 , 148 , 16 , 140
    .byte  9 , 134 , 4 , 130 , 1
    .byte  128 , 0 , 128 , 1 , 130
    .byte  4 , 134 , 9 , 140 , 16
    .byte  148 , 25 , 158 , 36 , 170
    .byte  49 , 184 , 64 , 200 , 81
    .byte  218 , 100 , 238 , 121 , 4
    .byte  144 , 28 , 169 , 54 , 196
    .byte  82 , 225 , 112 , 0 , 144
    .byte  33 , 178 , 68 , 214 , 105
    .byte  252 , 144 , 36 , 185 , 78
    .byte  228 , 122 , 17 , 168 , 64
    .byte  216 , 113 , 10 , 164 , 62
    .byte  217 , 116 , 16 , 172 , 73
    .byte  230 , 132 , 34 , 193 , 96
    .byte  0 , 160 , 65 , 226 , 132
    .byte  38 , 201 , 108 , 16 , 180
    .byte  89 , 254 , 164 , 74 , 241
    .byte  152 , 64 , 232 , 145 , 58
    .byte  228 , 142 , 57 , 228 , 144
    .byte  60 , 233 , 150 , 68 , 242
    .byte  161 , 80 , 0 , 176 , 97
    .byte  18 , 196 , 118 , 41 , 220
    .byte  144 , 68 , 249 , 174 , 100
    .byte  26 , 209 , 136 , 64 , 248
    .byte  177 , 106 , 36 , 222 , 153
    .byte  84 , 16 , 204 , 137 , 70
    .byte  4 , 194 , 129 , 64 , 0
    .byte  192 , 129 , 66 , 4 , 198
    .byte  137 , 76 , 16 , 212 , 153
    .byte  94 , 36 , 234 , 177 , 120
    .byte  64 , 8 , 209 , 154 , 100
    .byte  46 , 249 , 196 , 144 , 92
    .byte  41 , 246 , 196 , 146 , 97
    .byte  48 , 0 , 208 , 161 , 114
    .byte  68 , 22 , 233 , 188 , 144
    .byte  100 , 57 , 14 , 228 , 186
    .byte  145 , 104 , 64 , 24 , 241
    .byte  202 , 164 , 126 , 89 , 52
    .byte  16 , 236 , 201 , 166 , 132
    .byte  98 , 65 , 32 , 0 , 224
    .byte  193 , 162 , 132 , 102 , 73
    .byte  44 , 16 , 244 , 217 , 190
    .byte  164 , 138 , 113 , 88 , 64
    .byte  40 , 17 , 250 , 228 , 206
    .byte  185 , 164 , 144 , 124 , 105
    .byte  86 , 68 , 50 , 33 , 16
    .byte  0 , 240 , 225 , 210 , 196
    .byte  182 , 169 , 156 , 144 , 132
    .byte  121 , 110 , 100 , 90 , 81
    .byte  72 , 64 , 56 , 49 , 42
    .byte  36 , 30 , 25 , 20 , 16
    .byte  12 , 9 , 6 , 4 , 2
    .byte  1 


;******************** PLOT TABLE *********************
; offset low byte of each row
ytablelow:
    .byte 0,1,2,3,4,5,6,7
    .byte 64,65,66,67,68,69,70,71
    .byte 128,129,130,131,132,133,134,135
    .byte 192,193,194,195,196,197,198,199
    .byte 0,1,2,3,4,5,6,7
    .byte 64,65,66,67,68,69,70,71
    .byte 128,129,130,131,132,133,134,135
    .byte 192,193,194,195,196,197,198,199
    .byte 0,1,2,3,4,5,6,7
    .byte 64,65,66,67,68,69,70,71
    .byte 128,129,130,131,132,133,134,135
    .byte 192,193,194,195,196,197,198,199
    .byte 0,1,2,3,4,5,6,7
    .byte 64,65,66,67,68,69,70,71
    .byte 128,129,130,131,132,133,134,135
    .byte 192,193,194,195,196,197,198,199
    .byte 0,1,2,3,4,5,6,7
    .byte 64,65,66,67,68,69,70,71
    .byte 128,129,130,131,132,133,134,135
    .byte 192,193,194,195,196,197,198,199
    .byte 0,1,2,3,4,5,6,7
    .byte 64,65,66,67,68,69,70,71
    .byte 128,129,130,131,132,133,134,135
    .byte 192,193,194,195,196,197,198,199
    .byte 0,1,2,3,4,5,6,7


; offset high byte of each row
ytablehigh_BMP0:
    .byte >BMP0 + 0, >BMP0 + 0, >BMP0 + 0, >BMP0 + 0, >BMP0 + 0, >BMP0 + 0, >BMP0 + 0, >BMP0 + 0
    .byte >BMP0 + 1, >BMP0 + 1, >BMP0 + 1, >BMP0 + 1, >BMP0 + 1, >BMP0 + 1, >BMP0 + 1, >BMP0 + 1
    .byte >BMP0 + 2, >BMP0 + 2, >BMP0 + 2, >BMP0 + 2, >BMP0 + 2, >BMP0 + 2, >BMP0 + 2, >BMP0 + 2
    .byte >BMP0 + 3, >BMP0 + 3, >BMP0 + 3, >BMP0 + 3, >BMP0 + 3, >BMP0 + 3, >BMP0 + 3, >BMP0 + 3
    .byte >BMP0 + 5, >BMP0 + 5, >BMP0 + 5, >BMP0 + 5, >BMP0 + 5, >BMP0 + 5, >BMP0 + 5, >BMP0 + 5
    .byte >BMP0 + 6, >BMP0 + 6, >BMP0 + 6, >BMP0 + 6, >BMP0 + 6, >BMP0 + 6, >BMP0 + 6, >BMP0 + 6
    .byte >BMP0 + 7, >BMP0 + 7, >BMP0 + 7, >BMP0 + 7, >BMP0 + 7, >BMP0 + 7, >BMP0 + 7, >BMP0 + 7
    .byte >BMP0 + 8, >BMP0 + 8, >BMP0 + 8, >BMP0 + 8, >BMP0 + 8, >BMP0 + 8, >BMP0 + 8, >BMP0 + 8
    .byte >BMP0 + 10, >BMP0 + 10, >BMP0 + 10, >BMP0 + 10, >BMP0 + 10, >BMP0 + 10, >BMP0 + 10, >BMP0 + 10
    .byte >BMP0 + 11, >BMP0 + 11, >BMP0 + 11, >BMP0 + 11, >BMP0 + 11, >BMP0 + 11, >BMP0 + 11, >BMP0 + 11
    .byte >BMP0 + 12, >BMP0 + 12, >BMP0 + 12, >BMP0 + 12, >BMP0 + 12, >BMP0 + 12, >BMP0 + 12, >BMP0 + 12
    .byte >BMP0 + 13, >BMP0 + 13, >BMP0 + 13, >BMP0 + 13, >BMP0 + 13, >BMP0 + 13, >BMP0 + 13, >BMP0 + 13
    .byte >BMP0 + 15, >BMP0 + 15, >BMP0 + 15, >BMP0 + 15, >BMP0 + 15, >BMP0 + 15, >BMP0 + 15, >BMP0 + 15
    .byte >BMP0 + 16, >BMP0 + 16, >BMP0 + 16, >BMP0 + 16, >BMP0 + 16, >BMP0 + 16, >BMP0 + 16, >BMP0 + 16
    .byte >BMP0 + 17, >BMP0 + 17, >BMP0 + 17, >BMP0 + 17, >BMP0 + 17, >BMP0 + 17, >BMP0 + 17, >BMP0 + 17
    .byte >BMP0 + 18, >BMP0 + 18, >BMP0 + 18, >BMP0 + 18, >BMP0 + 18, >BMP0 + 18, >BMP0 + 18, >BMP0 + 18
    .byte >BMP0 + 20, >BMP0 + 20, >BMP0 + 20, >BMP0 + 20, >BMP0 + 20, >BMP0 + 20, >BMP0 + 20, >BMP0 + 20
    .byte >BMP0 + 21, >BMP0 + 21, >BMP0 + 21, >BMP0 + 21, >BMP0 + 21, >BMP0 + 21, >BMP0 + 21, >BMP0 + 21
    .byte >BMP0 + 22, >BMP0 + 22, >BMP0 + 22, >BMP0 + 22, >BMP0 + 22, >BMP0 + 22, >BMP0 + 22, >BMP0 + 22
    .byte >BMP0 + 23, >BMP0 + 23, >BMP0 + 23, >BMP0 + 23, >BMP0 + 23, >BMP0 + 23, >BMP0 + 23, >BMP0 + 23
    .byte >BMP0 + 25, >BMP0 + 25, >BMP0 + 25, >BMP0 + 25, >BMP0 + 25, >BMP0 + 25, >BMP0 + 25, >BMP0 + 25
    .byte >BMP0 + 26, >BMP0 + 26, >BMP0 + 26, >BMP0 + 26, >BMP0 + 26, >BMP0 + 26, >BMP0 + 26, >BMP0 + 26
    .byte >BMP0 + 27, >BMP0 + 27, >BMP0 + 27, >BMP0 + 27, >BMP0 + 27, >BMP0 + 27, >BMP0 + 27, >BMP0 + 27
    .byte >BMP0 + 28, >BMP0 + 28, >BMP0 + 28, >BMP0 + 28, >BMP0 + 28, >BMP0 + 28, >BMP0 + 28, >BMP0 + 28
    .byte >BMP0 + 30, >BMP0 + 30, >BMP0 + 30, >BMP0 + 30, >BMP0 + 30, >BMP0 + 30, >BMP0 + 30, >BMP0 + 30

ytablehigh_BMP1:
    .byte >BMP1 + 0, >BMP1 + 0, >BMP1 + 0, >BMP1 + 0, >BMP1 + 0, >BMP1 + 0, >BMP1 + 0, >BMP1 + 0
    .byte >BMP1 + 1, >BMP1 + 1, >BMP1 + 1, >BMP1 + 1, >BMP1 + 1, >BMP1 + 1, >BMP1 + 1, >BMP1 + 1
    .byte >BMP1 + 2, >BMP1 + 2, >BMP1 + 2, >BMP1 + 2, >BMP1 + 2, >BMP1 + 2, >BMP1 + 2, >BMP1 + 2
    .byte >BMP1 + 3, >BMP1 + 3, >BMP1 + 3, >BMP1 + 3, >BMP1 + 3, >BMP1 + 3, >BMP1 + 3, >BMP1 + 3
    .byte >BMP1 + 5, >BMP1 + 5, >BMP1 + 5, >BMP1 + 5, >BMP1 + 5, >BMP1 + 5, >BMP1 + 5, >BMP1 + 5
    .byte >BMP1 + 6, >BMP1 + 6, >BMP1 + 6, >BMP1 + 6, >BMP1 + 6, >BMP1 + 6, >BMP1 + 6, >BMP1 + 6
    .byte >BMP1 + 7, >BMP1 + 7, >BMP1 + 7, >BMP1 + 7, >BMP1 + 7, >BMP1 + 7, >BMP1 + 7, >BMP1 + 7
    .byte >BMP1 + 8, >BMP1 + 8, >BMP1 + 8, >BMP1 + 8, >BMP1 + 8, >BMP1 + 8, >BMP1 + 8, >BMP1 + 8
    .byte >BMP1 + 10, >BMP1 + 10, >BMP1 + 10, >BMP1 + 10, >BMP1 + 10, >BMP1 + 10, >BMP1 + 10, >BMP1 + 10
    .byte >BMP1 + 11, >BMP1 + 11, >BMP1 + 11, >BMP1 + 11, >BMP1 + 11, >BMP1 + 11, >BMP1 + 11, >BMP1 + 11
    .byte >BMP1 + 12, >BMP1 + 12, >BMP1 + 12, >BMP1 + 12, >BMP1 + 12, >BMP1 + 12, >BMP1 + 12, >BMP1 + 12
    .byte >BMP1 + 13, >BMP1 + 13, >BMP1 + 13, >BMP1 + 13, >BMP1 + 13, >BMP1 + 13, >BMP1 + 13, >BMP1 + 13
    .byte >BMP1 + 15, >BMP1 + 15, >BMP1 + 15, >BMP1 + 15, >BMP1 + 15, >BMP1 + 15, >BMP1 + 15, >BMP1 + 15
    .byte >BMP1 + 16, >BMP1 + 16, >BMP1 + 16, >BMP1 + 16, >BMP1 + 16, >BMP1 + 16, >BMP1 + 16, >BMP1 + 16
    .byte >BMP1 + 17, >BMP1 + 17, >BMP1 + 17, >BMP1 + 17, >BMP1 + 17, >BMP1 + 17, >BMP1 + 17, >BMP1 + 17
    .byte >BMP1 + 18, >BMP1 + 18, >BMP1 + 18, >BMP1 + 18, >BMP1 + 18, >BMP1 + 18, >BMP1 + 18, >BMP1 + 18
    .byte >BMP1 + 20, >BMP1 + 20, >BMP1 + 20, >BMP1 + 20, >BMP1 + 20, >BMP1 + 20, >BMP1 + 20, >BMP1 + 20
    .byte >BMP1 + 21, >BMP1 + 21, >BMP1 + 21, >BMP1 + 21, >BMP1 + 21, >BMP1 + 21, >BMP1 + 21, >BMP1 + 21
    .byte >BMP1 + 22, >BMP1 + 22, >BMP1 + 22, >BMP1 + 22, >BMP1 + 22, >BMP1 + 22, >BMP1 + 22, >BMP1 + 22
    .byte >BMP1 + 23, >BMP1 + 23, >BMP1 + 23, >BMP1 + 23, >BMP1 + 23, >BMP1 + 23, >BMP1 + 23, >BMP1 + 23
    .byte >BMP1 + 25, >BMP1 + 25, >BMP1 + 25, >BMP1 + 25, >BMP1 + 25, >BMP1 + 25, >BMP1 + 25, >BMP1 + 25
    .byte >BMP1 + 26, >BMP1 + 26, >BMP1 + 26, >BMP1 + 26, >BMP1 + 26, >BMP1 + 26, >BMP1 + 26, >BMP1 + 26
    .byte >BMP1 + 27, >BMP1 + 27, >BMP1 + 27, >BMP1 + 27, >BMP1 + 27, >BMP1 + 27, >BMP1 + 27, >BMP1 + 27
    .byte >BMP1 + 28, >BMP1 + 28, >BMP1 + 28, >BMP1 + 28, >BMP1 + 28, >BMP1 + 28, >BMP1 + 28, >BMP1 + 28
    .byte >BMP1 + 30, >BMP1 + 30, >BMP1 + 30, >BMP1 + 30, >BMP1 + 30, >BMP1 + 30, >BMP1 + 30, >BMP1 + 30

; offset low byte of each column
xtablelow:
    .byte 0,0,0,0,0,0,0,0
    .byte 8,8,8,8,8,8,8,8
    .byte 16,16,16,16,16,16,16,16
    .byte 24,24,24,24,24,24,24,24
    .byte 32,32,32,32,32,32,32,32
    .byte 40,40,40,40,40,40,40,40
    .byte 48,48,48,48,48,48,48,48
    .byte 56,56,56,56,56,56,56,56
    .byte 64,64,64,64,64,64,64,64
    .byte 72,72,72,72,72,72,72,72
    .byte 80,80,80,80,80,80,80,80
    .byte 88,88,88,88,88,88,88,88
    .byte 96,96,96,96,96,96,96,96
    .byte 104,104,104,104,104,104,104,104
    .byte 112,112,112,112,112,112,112,112
    .byte 120,120,120,120,120,120,120,120
    .byte 128,128,128,128,128,128,128,128
    .byte 136,136,136,136,136,136,136,136
    .byte 144,144,144,144,144,144,144,144
    .byte 152,152,152,152,152,152,152,152
    .byte 160,160,160,160,160,160,160,160
    .byte 168,168,168,168,168,168,168,168
    .byte 176,176,176,176,176,176,176,176
    .byte 184,184,184,184,184,184,184,184
    .byte 192,192,192,192,192,192,192,192
    .byte 200,200,200,200,200,200,200,200
    .byte 208,208,208,208,208,208,208,208
    .byte 216,216,216,216,216,216,216,216
    .byte 224,224,224,224,224,224,224,224
    .byte 232,232,232,232,232,232,232,232
    .byte 240,240,240,240,240,240,240,240
    .byte 248,248,248,248,248,248,248,248
; X > 255
.ifdef USE_X16
    .byte 0,0,0,0,0,0,0,0
    .byte 8,8,8,8,8,8,8,8
    .byte 16,16,16,16,16,16,16,16
    .byte 24,24,24,24,24,24,24,24
    .byte 32,32,32,32,32,32,32,32
    .byte 40,40,40,40,40,40,40,40
    .byte 48,48,48,48,48,48,48,48
    .byte 56,56,56,56,56,56,56,56

; offset high byte of each column
xtablehigh:
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
; X > 255
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
.endif ; USE_X16

; convert X to bit
bitable:
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
    .byte 128,64,32,16,8,4,2,1
; table wraps for X > 255


.segment	"CODE"
.proc	_main: near


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

	lda $d018
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
loopcol:
	sta	23552,x		;sta	$400,x
	sta	23552+256,x	;sta	$500,x
	sta	23552+512,x	;sta	$600,x
	sta	23552+768,x	;sta	$700,x
	inx
	bne	loopcol

; set white pen on dark blue paper (also clears sprite pointers) on screen 1

	ldx	#$00
	lda	#22
loopcol2:
    sta	1024,x		;sta	$400,x
	sta	1024+256,x	;sta	$500,x
	sta	1024+512,x	;sta	$600,x
	sta	1024+768,x	;sta	$700,x
	inx
	bne	loopcol2
        jsr clear_BMP0
        jsr clear_BMP1


; test point
;X1_ = 70
;Y1_ = 31
;    lda #>X1_   ; high byte
;    sta x1
;    lda #<X1_   ; low byte
;    sta x1 + 1
;    lda #Y1_
;    sta y1
;    jsr plot

; test line
;X1 = 0
;Y1 = 0
;X2 = 255
;Y2 = 100
;    lda #>X1
;    sta x1
;    lda #<X1
;    sta x1+1
;    lda #Y1
;    sta y1
;    lda #>X2
;    sta x2
;    lda #<X2
;    sta x2+1
;    lda #Y2
;    sta y2
;    jsr line_subroutine
;    rts



; draw 3d cube
    lda #0
    sta rx                  ;set rotation angle to 0

cube_loop:
    ldx rx
    lda cos_tables, x
    sta c 

    lda sin_tables, x 
    sta s 

    lda #0                  ;loop counter for eight points (from 0 to 7)
    sta point_index 
                
rotate_loop:
; computes yd(np) = (c*yt-s*z(np))/offset
    ldy point_index



.ifdef ROTATE_Y
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

; compute zd(np) =(s*yt + c*z(np))/offset
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

.endif ; ROTATE_Y



.ifdef ROTATE_XY
; rotation about x axis 
; compute yd(np) = (c*yt-s*z(np))/offset
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




; compute zd(np) =(s*yt + c*z(np))/offset
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
    sta temp_z              ;used for the following formula 



; rotation about y axis 
; compute xd(np) = (c*xt+s*zt)/offset
    ldy point_index 
    lda x_component, y 
    sta temp_x 
    lda c
    sta multiplicand8
    lda temp_x
    sta multiplier8 
    jsr multiply_ab8        ;c * xt
    lda multiplier8
    sta prod
    lda sum8
    sta prod+1              ;prod <--- c * xt

    ldy point_index 
    lda s
    sta multiplicand8
    lda temp_z 
    sta multiplier8 
    jsr multiply_ab8        ;s*zt
    clc 
    lda prod+1
    adc sum8
    sta prod+1
    lda prod
    adc multiplier8
    sta prod                ;prod<---- prod+s*z(np) 
    jsr divide_prod_signed         ;divide prod by offset 64

    ldy point_index 
    lda prod+1
    sta xd_component, y

; compute zd(np) =(c*zt-s*xt)/offset

    ldy point_index 
    lda c
    sta multiplicand8
    lda temp_z 
    sta multiplier8 
    jsr multiply_ab8        ;c * zt 
    lda multiplier8
    sta prod
    lda sum8
    sta prod+1              ;prod <--- c * zt 
    lda s
    sta multiplicand8
    lda temp_x  
    sta multiplier8 
    jsr multiply_ab8        ;s*xt  
    sec
    lda prod+1
    sbc sum8
    sta prod+1
    lda prod
    sbc multiplier8
    sta prod                ;prod<---- prod-s*xt 
    jsr divide_prod_signed         ;divide prod by offset 64

    ldy point_index 
    lda prod+1
    sta zd_component, y

.endif ; ROTATE_XY




; project xd 
    lda zd_component, y 
    bpl positive_zd
    sec
    lda #$00
    sbc zd_component,y 
    tax                     ;takes complement of zd and puts it in x 
    lda projneg, x          ;loads negative value of projection coefficient
    jmp skip_positive_zd


positive_zd:
    ldx zd_component, y
    lda projpos, x          ;loads positive value of projection coefficient 

skip_positive_zd:
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


positive_zd2:
    ldx zd_component, y    
    lda projpos, x          ;loads positive value of projection coefficient 
                
skip_positive_zd2:
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
        jmp draw_it 
jump_rotate_loop:
    jmp rotate_loop 
                
				
draw_it:
;draws the cube
    lda current_screen 
    bne use_screen2 
;        jsr clear_BMP0      ; clear entire screen
        jsr clear_part_BMP0  ; clear part of screen
                             ; switch from buffer2 to buffer1
        jmp skip_use_screen2

use_screen2:
;    jsr clear_BMP1      ; clear entire screen
    jsr clear_part_BMP1  ; clears part of screen
                         ; start base on plot: actual_screen+2, actual_screen+3
                         ; switch from buffer 1 to buffer 2 

skip_use_screen2:
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
    lda current_screen
    bne screen2_active
        jsr alt_mem
        jmp skip_alt_mem
                
screen2_active:
    jsr pref_mem  
                
                
skip_alt_mem:
    lda current_screen
    eor #$01
    sta current_screen         ;switchs flag for double buffering 

;key_read_loop   jsr $ffe4
;                beq key_read_loop
    inc rx
    lda rx 
    cmp #63 
    bne jump_cube_loop 
        jmp skip_jump_cube_loop
jump_cube_loop:
    jmp cube_loop
skip_jump_cube_loop:
    lda #$00
    sta rx 
    jmp cube_loop 










; 8 bit X only
line_subroutine:
; computes deltax, deltay, decides what routine to be used
    ;lda x1
    ;cmp x2
    ;bcc compute_delta_x2_x1
    ;bne compute_delta_x1_x2        ;high bytes unused
    lda x1+1
    cmp x2+1
    bcc compute_delta_x2_x1			;compares x1 and x2 

compute_delta_x1_x2:
    sec
    lda x1+1
    sbc x2+1
    sta delta_x+1
    ;lda x1
    ;sbc x2
    ;sta delta_x				;delta_x = x1-x2

    lda #$01
    sta x_n					    ;delta_x negative

    jmp skip_compute_delta_x2_x1

compute_delta_x2_x1:
    sec
    lda x2+1
    sbc x1+1
    sta delta_x+1
    ;lda x2
    ;sbc x1 
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

    INC     x1+1	                        ;Step in x
    jmp     skip_dec_x 

dec_x:
    DEC     x1+1 

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
    lda     x1+1
    cmp     limit 	                        ;At the endpoint yet?
    bne	LOOPL
    RTS


;fast line for dy > dx
line_170:
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

    INC	x1+1	                        ;Step in x

    jmp     skip_dec_x2

dec_x2:
    dec     x1+1 

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
    ldx x1 + 1        ; X low byte  -> X


.ifdef USE_X16
; reset the lookup table after the last plot command
    lda #>xtablehigh
    sta XTBmdf + 2	  ; self modifying code

    lda x1            ; X high byte -> A
    beq skipadj       ; branch if high byte 0

; add high byte to the lookup table so the index can be only 8 bits
        lda #>(xtablehigh + $ff)		;added brackets, otherwise it won't work
        sta XTBmdf + 2	  ; self modifying code
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
XTBmdf:
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


; clear entire bitmap screen
clear_BMP0:
	ldy	#32
    lda	#>BMP0	; set starting address
	sta	mod1 + 2
	sta	mod2 + 2
	sta	mod3 + 2
	sta	mod4 + 2
	sta	mod5 + 2
	lda	#<BMP0
	sta	mod1 + 1	
	sta	mod2 + 1	
	sta	mod3 + 1	
	sta	mod4 + 1	
	sta	mod5 + 1	

loopbmp:
	ldx	#250
	lda	#$00            ;filling value 

loopbmp2:
	dex
mod1:
	sta	BMP0,x
	dex
mod2:
	sta	BMP0,x
	dex
mod3:
	sta	BMP0,x
	dex
mod4:
	sta	BMP0,x
	dex
mod5:
	sta	BMP0,x
	bne	loopbmp2
	    clc
	    lda	mod1+1
	    adc	#250
	    sta	mod1+1
	    sta	mod2+1
	    sta	mod3+1
	    sta	mod4+1
	    sta	mod5+1
	    lda	mod1+2
	    adc	#00
	    sta	mod1+2
	    sta	mod2+2
	    sta	mod3+2
	    sta	mod4+2
	    sta	mod5+2
	    dey
	    bne	loopbmp
	        rts
                

; clear entire bitmap screen
clear_BMP1:
	ldy	#32
    lda	#>BMP1	;initialize self modifying code
	sta	mod1 + 2
	sta	mod2 + 2
	sta	mod3 + 2
	sta	mod4 + 2
	sta	mod5 + 2
	lda	#<BMP1
	sta	mod1 + 1	
	sta	mod2 + 1	
	sta	mod3 + 1	
	sta	mod4 + 1	
	sta	mod5 + 1	
	jmp loopbmp


; clear part of bmp screen
OFFSETC = 1999-320+16
clear_part_BMP1:
     ;8192
    lda #$00

.ifdef BIGGER
    ldx #128

clear_part_loop:
    sta BMP1+OFFSETC,x
    sta BMP1+OFFSETC+320,x
    sta BMP1+OFFSETC+640,x
    sta BMP1+OFFSETC+960,x
    sta BMP1+OFFSETC+1280,x
    sta BMP1+OFFSETC+1600,x
    sta BMP1+OFFSETC+1920,x
    sta BMP1+OFFSETC+2240,x
    sta BMP1+OFFSETC+2560,x
    sta BMP1+OFFSETC+2880,x
    sta BMP1+OFFSETC+3200,x
    sta BMP1+OFFSETC+3520,x
    sta BMP1+OFFSETC+3840,x
    sta BMP1+OFFSETC+4160,x
    sta BMP1+OFFSETC+4480,x
.else
    ldx #80
clear_part_loop:
    sta BMP1+2359,x
    sta BMP1+2359+320,x
    sta BMP1+2359+640,x
    sta BMP1+2359+960,x
    sta BMP1+2359+1280,x
    sta BMP1+2359+1600,x
    sta BMP1+2359+1920,x
    sta BMP1+2359+2240,x
    sta BMP1+2359+2560,x
    sta BMP1+2359+2880,x
    sta BMP1+2359+3200,x
.endif

    dex 
    bne clear_part_loop
    rts 

clear_part_BMP0:
     ;24576
    lda #$00
.ifdef BIGGER
    ldx #128
clear_part_loopbis:
    sta BMP0+OFFSETC,x
    sta BMP0+OFFSETC+320,x
    sta BMP0+OFFSETC+640,x
    sta BMP0+OFFSETC+960,x
    sta BMP0+OFFSETC+1280,x
    sta BMP0+OFFSETC+1600,x
    sta BMP0+OFFSETC+1920,x
    sta BMP0+OFFSETC+2240,x
    sta BMP0+OFFSETC+2560,x
    sta BMP0+OFFSETC+2880,x
    sta BMP0+OFFSETC+3200,x
    sta BMP0+OFFSETC+3520,x
    sta BMP0+OFFSETC+3840,x
    sta BMP0+OFFSETC+4160,x
    sta BMP0+OFFSETC+4480,x
.else
    ldx #80
clear_part_loopbis:
    sta BMP0+2359,x
    sta BMP0+2359+320,x
    sta BMP0+2359+640,x
    sta BMP0+2359+960,x
    sta BMP0+2359+1280,x
    sta BMP0+2359+1600,x
    sta BMP0+2359+1920,x
    sta BMP0+2359+2240,x
    sta BMP0+2359+2560,x
    sta BMP0+2359+2880,x
    sta BMP0+2359+3200,x
.endif

    dex 
    bne clear_part_loopbis
    rts 






; bitmap memory from 8192, screen memory from 1024, standard 16k bank 
                
pref_mem:
raster2:
    lda 53265
    bpl raster2 

; set up plot function
    lda #<ytablehigh_BMP0
    sta ytablemod + 1
    lda #>ytablehigh_BMP0
    sta ytablemod + 2

	ldy	#28
	sty	$d018		;bitmap base 8192

    lda $d018
    and #15
    ora #16
    sta $d018           ;default video screen memory (1024) 

    lda	#$17
	sta	$dd00		;default vic-ii bank
    rts

                
; bitmap memory from 24576, screen memory from 23552 
alt_mem:
raster1:
    lda 53265
    bpl raster1

; set up plot function
    lda #<ytablehigh_BMP1
    sta ytablemod + 1
    lda #>ytablehigh_BMP1
    sta ytablemod + 2

	lda $d018
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


; signed divide by offset 64 (prod, prod+1) 
divide_prod_signed:
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

skip_comp_divide_signed2:
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

comp_quotient2:
    lda #$00
    sbc prod+1
    sta prod+1
    rts 


; signed divide by offset 64 (multiplier8, sum8) 
divide_signed:
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

skip_comp_divide_signed:
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

comp_quotient:
    sec
    lda #$00
    sbc sum8
    sta sum8

    rts 


; signed 8 bit multiply (used for rotations and projections)
multiply_ab8:
	lda	#$00
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

;multiplicand8 sign set to negative
    inc     multiplicand_sign8 
                
skip_multiplicand_comp8:
    lda     multiplier8
    bpl     loop8            ;checks sign on high byte

    sec

    lda     #<256
    sbc     multiplier8
    sta     multiplier8      ;takes complement of multiplier8 


;multiplier8 sign set to negative
    inc     multiplier_sign8 


; fast multiply 

loop8:       
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
                
skip_inc:
    tax             

    sec
    lda multiplicand8
    sbc multiplier8             
    bcs no_diff_fix

    sec
    lda multiplier8
    sbc multiplicand8
                
no_diff_fix:    
    tay
    sec
mod12:
    lda square_low,x 
    sbc square_low,y
    sta sum8

                
mod22:
    lda square_high, x
    sbc square_high, y
    sta multiplier8



; multiplier8 is high byte, sum8 is low byte 
; sign of product evaluation

    lda multiplicand_sign8
    eor multiplier_sign8         


;if product is positive, skip product complement
    beq skip_product_complement8 

    sec
    lda #< 65536
    sbc sum8
    sta sum8
    lda #> 65536
    sbc multiplier8
;takes 2 complement of product (16 bit)
    sta multiplier8         
                

skip_product_complement8:
	rts
                


.endproc
