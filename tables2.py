#!/usr/bin/python
# compute the tables for budge graphics

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


ytablelo = []


for i in range(0, 25):
    for j in range(0, 8):
        ytablelo.append(((i * 64 + j) & 0xff) + 32)

print_table(ytablelo, "YTableLo:")

