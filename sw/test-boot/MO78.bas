REM MO78 - test an 80 column mode 7
MODE7:REM select mode 7 first
HIMEM=&7800:REM move HIMEM down for our 2K screen
REM write updated CRTC registers 
FORI%=0TO13:READN%:VDU 23,0,I%,N%,0;0;0;0;0;:NEXT   
REM poke ULA for 2MHZ teletext mode
?&248=&5B
?&FE20=&5B
REM load a test page
*LOAD  8.TT80 7800
REPEAT:UNTIL FALSE
:
DATA &7F,&50,&62,&28,&1E,&02,&19,&1B,&93,&12,&72,&13,&30,&00
