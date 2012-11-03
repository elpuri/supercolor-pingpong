supercolor-pingpong
===================

Jackie Chan's SUPER COLOR Ping Pong! is an action packed family friendly
ping pong simulator written in VHDL. To play it you need a PS2 keyboard,
VGA monitor and an FPGA board. I expect the game to become a worldwide hit
and justify an ASIC run by 2014 latest. 

Demo video: http://www.youtube.com/watch?v=2aTpoUg0NKQ

It should synthesize nicely as-is for Altera FPGAs. If you want to target
something else, you'll need to replace the graphics roms with your vendor's
megafunctions. The Quartus II project under the quartus subdirectory has 
pin assignments for the Altera DE2 board.

Move paddles with A/Z and up/down arrows. Launch the ball with space. Enjoy.