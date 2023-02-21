#!/usr/bin/python

# generate the trig tables
# values are -127 to 127

import math


def print_table(data, text):
    print(text)
    string = ""
    line = 0
    for i in range(0, len(data)):
        if line == 0:
            string = "    .byte "
        if line > 0:
            string += ", "

        string += "$%02x" % data[i]
        line += 1
        if line >= 8:
            print(string)
            line = 0
    if line > 0:
        print(string)
    

# convert original signed projection tables to a single unsigned table
def proj_table():
# original had 255 positive values, only 128 of which could be used
# points get smaller as Z increases
    projpos = [
        64, 63, 63, 63, 62, 62,
        62, 61, 61, 61, 60, 60,
        60, 60, 59, 59, 59, 58,
        58, 58, 58, 57, 57, 57,
        57, 56, 56, 56, 56, 55,
        55, 55, 55, 54, 54, 54,
        54, 54, 53, 53, 53, 53,
        52, 52, 52, 52, 52, 51,
        51, 51, 51, 50, 50, 50,
        50, 50, 50, 49, 49, 49,
        49, 49, 48, 48, 48, 48,
        48, 47, 47, 47, 47, 47,
        47, 46, 46, 46, 46, 46,
        46, 45, 45, 45, 45, 45,
        45, 44, 44, 44, 44, 44,
        44, 43, 43, 43, 43, 43,
        43, 43, 42, 42, 42, 42,
        42, 42, 42, 41, 41, 41,
        41, 41, 41, 41, 41, 40,
        40, 40, 40, 40, 40, 40,
        40, 39, 39, 39, 39, 39,
        39, 39, 39, 38, 38, 38,
        38, 38, 38, 38, 38, 37,
        37, 37, 37, 37, 37, 37,
        37, 37, 36, 36, 36, 36,
        36, 36, 36, 36, 36, 36,
        35, 35, 35, 35, 35, 35,
        35, 35, 35, 35, 34, 34,
        34, 34, 34, 34, 34, 34,
        34, 34, 34, 33, 33, 33,
        33, 33, 33, 33, 33, 33,
        33, 33, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32,
        32, 32, 32, 31, 31, 31,
        31, 31, 31, 31, 31, 31,
        31, 31, 31, 30, 30, 30,
        30, 30, 30, 30, 30, 30,
        30, 30, 30, 30, 30, 29,
        29, 29, 29, 29, 29, 29,
        29, 29, 29, 29, 29, 29,
        29, 29, 28, 28, 28, 28,
        28, 28, 28, 28, 28, 28,
        28, 28, 28, 28
    ]
# original had 100 negative values
# points get bigger as Z decreases
    projneg = [
        64, 64, 64, 64, 65,
        65, 65, 66, 66, 67,
        67, 67, 68, 68, 68,
        69, 69, 69, 70, 70,
        71, 71, 71, 72, 72,
        73, 73, 73, 74, 74,
        75, 75, 76, 76, 77,
        77, 78, 78, 79, 79,
        80, 80, 81, 81, 82,
        82, 83, 83, 84, 84,
        85, 85, 86, 87, 87,
        88, 88, 89, 90, 90,
        91, 92, 92, 93, 94,
        94, 95, 96, 96, 97,
        98, 99, 100, 100, 101,
        102, 103, 104, 104, 105,
        106, 107, 108, 109, 110,
        111, 112, 113, 114, 115,
        116, 117, 118, 119, 120,
        121, 123, 124, 125, 126
    ]

    data = []
# positive projection coefficients
# only use 128 of the total 255
    for i in range(0, 128):
        data.append(projpos[i])

# negative projection coefficients
# pad -128 to -100
    for i in range(0, 128 - len(projneg)):
        data.append(projneg[len(projneg) - 1])

# -100 to -1
    for i in range(0, len(projneg)):
        data.append(projneg[len(projneg) - i - 1])

    print_table(data, "\nproj_table:")




# cos table is just the sin table with an offset of 64
def sin_table():
    data = []
    string = ""
    line = 0
    for i in range(0, 320):
        data.append(math.sin(float(i) / 256 * 2 * math.pi))
        data[i] = int(data[i] * 127) & 0xff
    print_table(data[0:64], "sin_table:")
    print_table(data[64:320], "cos_table:")

#cos_table()
sin_table()
#proj_table()
