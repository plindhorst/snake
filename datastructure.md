Screen needs to be 4032 pixels (84 x 48)
On the edges there are 1-pixel walls surrounded by 1 pixel of empty space on both sides, so game area maps to 3276 pixels (78 x 42).
Pixel info is found at (rows x 84) + cols - a 2D array
This is altered in every loop, then written to screen.
Pixel info should be 0x0 or 0x1.

A snake block is a 3x3. This means the game area is 364 blocks (26 x 14).
Coordinates of the snake blocks are stored in a queue structure made on top of an array, these coordinates are just integer values from 0 to 4031, mapping to the game screen, meaning the top left corner of the block.

Coordinate 255 is thus the coordinate for top-left-most location on the game area (3 84's for the top wall and 3 for the left one), and each move right is +3, move left is -3, move down is +252 and move up is -252.

The apple is also a 3x3, but displayed as follows:
```
 X
X X
 X
```
So the first line should be 010, then 101 and finally another 010.
This is also stored as a top-left corner coordinate in a global variable. To map this coordinate into actual writable pixels:
- px1 = coord + 1
- px2 = coord + 84
- px3 = coord + 86
- px4 = coord + 169


Storing things like this makes it easy to check if
1) snakehead = apple (coords match) and if
2) snakehead = wall (head coord out of bounds) or
3) snakehead = any-other-snake-block (pixels add up to 2).
