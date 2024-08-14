#!/usr/bin/python

#
# GLXGears for commodore 64
#
# Copyright (C) 2023-2024 Adam Williams <broadcast at earthling dot net>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 

# generate XYZ gear models for glxgears3.s

# python genmodels2.py > gearmodel.s


import math


def to_hex8(n):
    hex_table = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
        'a', 'b', 'c', 'd', 'e', 'f' ]
    string = '$' + hex_table[n >> 4] + hex_table[n & 0xf]
    return string

def print_table(data, text):
    print(text)
    string = ""
    line = 0
    for i in range(0, len(data)):
        if line == 0:
            string = "    .byte "
        if line > 0:
            string += ", "

        string += to_hex8(int(data[i]))
        line += 1
        if line >= 8:
            print(string)
            line = 0
    if line > 0:
        print(string)
    

# polar to XY
def toXY(r, a):
    x = r * math.cos(a)
    y = r * math.sin(a)
    return [x, y]

# generate a 3D gear
# from https://github.com/davidanthonygardner/glxgears/blob/master/glxgears.c
# and 3d_arduino/genmodel.py
def gear(inner_radius, outer_radius, teeth, tooth_depth, shaft_points, w, n):
    x_coords = []
    y_coords = []
    z_coords = []
    line_start_point = []
    line_end_point = []
    shape_start_point = []
    shape_end_point = []
    shape_start_line = []
    shape_end_line = []
    r0 = inner_radius
    r1 = outer_radius - tooth_depth / 2.0
    r2 = outer_radius + tooth_depth / 2.0
    da = 2.0 * math.pi / teeth / 4.0

# create teeth
    gear_start = len(x_coords)
    for side in range(2):
        if side == 0:
            z = -w
        else:
            z = w
        start_len = len(x_coords)
        for i in range(0, teeth):
            angle0 = i * 2.0 * math.pi / teeth;
            angle1 = angle0 + da
            angle2 = angle0 + 2 * da
            angle3 = angle0 + 3 * da
            point0 = toXY(r1, angle0)
            point1 = toXY(r2, angle1)
            point2 = toXY(r2, angle2)
            point3 = toXY(r1, angle3)
# finish  previous line
            if i > 0: 
                line_end_point.append(len(x_coords))
# start next line
            line_start_point.append(len(x_coords))
            x_coords.append(point0[0])
            y_coords.append(point0[1])
            z_coords.append(z)
            line_end_point.append(len(x_coords))
            line_start_point.append(len(x_coords))
            x_coords.append(point1[0])
            y_coords.append(point1[1])
            z_coords.append(z)
            line_end_point.append(len(x_coords))
            line_start_point.append(len(x_coords))
            x_coords.append(point2[0])
            y_coords.append(point2[1])
            z_coords.append(z)
            line_end_point.append(len(x_coords))
            line_start_point.append(len(x_coords))
            x_coords.append(point3[0])
            y_coords.append(point3[1])
            z_coords.append(z)
# finish last line
            if i == teeth - 1:
                line_end_point.append(start_len)

# create shaft
    shaft_start = len(x_coords)
    for side in range(2):
        if side == 0:
            z = -w
        else:
            z = w
        start_len = len(x_coords)
        for i in range(0, shaft_points):
            angle = i * 2.0 * math.pi / shaft_points
            point = toXY(r0, angle)
# finish  previous line
            if i > 0: 
                line_end_point.append(len(x_coords))
# start next line
            line_start_point.append(len(x_coords))
            x_coords.append(point[0])
            y_coords.append(point[1])
            z_coords.append(z)
# finish last line
            if i == shaft_points - 1:
                line_end_point.append(start_len)

# create joining lines
    for i in range(0, teeth):
        for j in range(0, 4):
            line_start_point.append(gear_start + i * 4 + j)
            line_end_point.append(gear_start + teeth * 4 + i * 4 + j)
    for i in range(0, shaft_points):
        line_start_point.append(shaft_start + i)
        line_end_point.append(shaft_start + shaft_points + i)

# print the table
    print_table(x_coords, "Gear%dXCoords:" % n)
    print_table(y_coords, "Gear%dYCoords:" % n)
    print_table(z_coords, "Gear%dZCoords:" % n)

    print_table(line_start_point, "Gear%dLineStart:" % n)
    print_table(line_end_point, "Gear%dLineEnd:" % n)

    print("Gear%dTotalPoints := %d" % (n, len(x_coords)))
#    print("Gear%dFirstLineStartAddress := Gear%dLineStart" % (n, n))
    print("Gear%dLastLineStart := Gear%dLineStart + %d" % (n, n, len(line_start_point)))
#    print("Gear%dFirstLineEndAddress := Gear%dLineEnd" % (n, n))
    print("")





# from 3d_arduino/genmodel.py
gear(10, # inner_radius
    50,  # outer_radius
    20,  # teeth
    10,  # tooth_depth
    8,   # shaft_points
    10,  # w
    1)   #n

gear(15, # inner_radius
    25,  # outer_radius
    10,  # teeth
    10,  # tooth_depth
    8,   # shaft_points
    5,   # w
    2)   # n

gear(5, # inner_radius
    25, # outer_radius
    10, # teeth
    10, # tooth_depth
    4,  # shaft_points
    20, # w
    3)  # n











