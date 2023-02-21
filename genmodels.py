#!/usr/bin/python

#
# GLXGears for commodore 64
#
# Copyright (C) 2023 Adam Williams <broadcast at earthling dot net>
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

# generate gear models in polar coordinates
# these are rotated by the Z rotation & converted to XY coordinates at runtime

# There is 1 output table for each polygon.  
# Each point has r & angle in hex.  Radius is 0-0xff Angle is 0-0x3f
# Each gear has 2 polygons: teeth & shaft

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
    
def toAngle(a):
    return int(a * 255 / 2 / math.pi)


# tabulate sin * r
def circle_table(sin_title, cos_title, r):
    data = []
    for i in range(0, 320):
        data.append(r * math.sin(float(i) / 256 * 2 * math.pi));
        data[i] = int(data[i]) & 0xff
        
        
    print_table(data[0:64], sin_title)
# cos overlaps sin
    print_table(data[64:320], cos_title)

# generate a 2D gear
# from https://github.com/davidanthonygardner/glxgears/blob/master/glxgears.c
# and 3d_arduino/genmodel.py
def gear(inner_radius, outer_radius, teeth, tooth_depth, shaft_points, gear, shaft):
# premultiplied sin * cos for every angle
# sin * (outer radius - tooth_depth / 2.0)
    circle_table(gear + '_sin_r1:', gear + '_cos_r1:', outer_radius - tooth_depth / 2.0)
# sin * (outer radius + tooth_depth / 2.0)
    circle_table(gear + '_sin_r2:', gear + '_cos_r2:', outer_radius + tooth_depth / 2.0)
# sin * inner radius
    circle_table(shaft + '_sin_r:', shaft + '_cos_r:', inner_radius)

# angle tables
    teeth_a = []
    shaft_a = []
    r0 = inner_radius
    r1 = outer_radius - tooth_depth / 2.0
    r2 = outer_radius + tooth_depth / 2.0
    da = 2.0 * math.pi / teeth / 4.0

# teeth angles
    for i in range(0, teeth + 1):
       angle = i * 2.0 * math.pi / (teeth + 1);
       teeth_a.append(toAngle(angle))
       teeth_a.append(toAngle(angle + da))
       teeth_a.append(toAngle(angle + 2 * da))
       teeth_a.append(toAngle(angle + 3 * da))

# shaft angles
    for i in range(0, shaft_points):
        angle = i * 2.0 * math.pi / shaft_points
        shaft_a.append(toAngle(angle))

    print_table(teeth_a, gear + "_angles:")
    print_table(shaft_a, shaft + "_angles:")
    string2 = shaft + "_n = %d" % len(shaft_a)
    string1 = gear + "_n = %d" % len(teeth_a)
    print(string1.upper())
    print(string2.upper())
    print("; total bytes: %s" % \
        (3 * 320 + len(teeth_a) + len(shaft_a)))
    



# from 3d_arduino/genmodel.py
#gear(10, 50, 20, 5, 10, "gear1", "shaft1")
gear(20, 70, 10, 20, 10, "gear1", "shaft1")















