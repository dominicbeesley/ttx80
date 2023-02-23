# TTX80 - 80 column teletext for the BBC Micro

This project contains schematics and code for an 80 column board for the BBC
Model B using a modification that replaces IC's 37, 39 and 11 with a mezzanine 
board. The original chips are relocated to the board. When 80 column mode is
selected the 1 and 6MHz signals to the SAA5050 chip are replaced with 2 and 
12MHz instead.

80 column mode is selected by programming the CRTC such that the screen is 
in the character cell address range (MA13..0). This sets the ULA and address
selection into teletext mode and in addition forces the screen to come from
the top 16K of memory. The hardware scroll wrap around is changed to cater
for the larger (2K) memory map.

A 74HC7046 PLL chip generates clean 12 and 2 or 6 and 1MHz clocks instead of 
the original marginal 6MHz circuit. 

