// test program for getting calling conventions to C functions


#include <conio.h>

void main()
{
    while(1)
    { 
        unsigned char c = cgetc();
        cprintf("%02x\r\n", c);
    }
}




