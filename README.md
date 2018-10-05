### Konsta Kanniainen (kkanniainen)
### Paul Lindhorst (plindhorst)
### TU Delft

# Specification for Snake in x86_64 assembly


Compile with:
"gcc -g -o snake -lSDL2 -no-pie snake.s"

The aim of this project is to create a game of Snake, as seen in 1990’s Nokia mobile phones. In this game a snake moves around a 2-dimensional, fixed map, and should not crash in the walls or itself. As well as the snake, there will be apples (one at a time) on the map. Moving the snake’s head over these apples will score the player points, but it will also make the snake grow.


Graphics:
Game area 84 x 48 pixels, scaled up by a factor of 4 to make it playable on a bigger screen
Using the SDL library version 2
Aim to recreate the original greenscale colors

Sound:
Every time an apple is eaten, a beep is played

Controls:
Keyboard up, down, right and left to redirect the snake
Difficulty level passed as a command line argument (1-9, defaults to 5). Difficulty level maps to frames per second, faster speed making the game more difficult but resulting in more points per apple.

Game over:
Should display a screen with player’s score
When player presses any key now, they can see the highscore table
When player presses any key at the highscores, program should quit

Technical definitions:
A Linux application - project uses git for version control
Snake is stored in a queue-like data structure (actual implementation TBD)
Init function should: init the graphic frame, set the initial position and direction of the snake, set the position of the first apple
Each game loop should: get keycode, detect possible crash, set a new head for the snake, remove the tail if the snake didn’t eat in the last loop, set a new apple and play a beep if it did
End function should: display player’s score, wait for a keycode, display highscores, wait for a keycode, exit
