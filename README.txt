ServoController8

System Clock is 18.432 MHz

Controlls upto eight servos at a time

255 steps of resolution (0-254), 255 is not allowed or can be used as a reset. Read the
	comments in the source code to see how to use it as reset.

Two byte packets:
***first byte is the servo number (0-7)
***second byte is the position value (0-254)

Uses spi to communicate
***Sample rising, setup falling (cpol = 0, cpha = 0)
***Data order msb transmitted first
***Fosc/16 @18.432 MHz to avoid it tripping over its self.

Several diptrace layouts are included. Some are suitable for single sided home etching
with air wires and some are suitable for etching by IMall. 

 





   