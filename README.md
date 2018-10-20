###### Konsta Kanniainen
###### Paul Lindhorst
###### Technische Universiteit Delft

# Snake in x86_64 assembly


The aim of this project was to create a game of Snake, a tribute to the one seen in 1990’s Nokia mobile phones. Making a game in assembly was a bonus assignment of the Computer Organization course at TU Delft.

Controls:
- Keyboard up, down, right and left to redirect the snake
- Difficulty level passed as a command line argument (1-9, defaults to 5). Difficulty level maps to frames per second, faster speed making the game more difficult but resulting in more points per apple.

Highscores are not saved to disk so they will be zeroed every time the game is launched.

Dependencies:
libsdl2-dev
libsdl2-ttf-dev
libsdl2-mixer-dev

Compile with:
"gcc -o snake -lSDL2 -lSDL2_ttf -lSDL2_mixer -no-pie snake.s"

Launch with:
"./snake *difficulty*" where *difficulty* is a number between 1-9 (optional, defaults to 5).
