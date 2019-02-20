# Pong
For one of my Computer Science classes, we had a bit of free rein to submit whatever we wanted for an assignment. 
The only real constraints were that it had to run on an ARM chip, and be written (at least partially) in the RISC-V Assembly instruction set.

## Code Notes
If you're looking for a general breakdown of the system, there is a overall breakdown in the main file '_kernel7.asm_'.

'_timer2-2Param.asm_' is used to restrict the frame draw rate of the system, so that it can run at 60FPS. This also helps to throttle the performance of the system so that it will run at 60FPS on all ARM chips, regardless of the chip's clock speed.

## Hardware Requirements
* Rasperry Pi 3B+
* A number of connection wires
* Breadboard (any size)
* Some buttons & resistors (for voltage pull-down)
* A Screen
* A _lot_ of time

## Known Issues
* Collision detection of the ball
* Player 2 (right-hand side) Paddle movement
