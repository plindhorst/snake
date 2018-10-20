# Variables
.data
    # Gameplay variables
    # Contains the block number for the current apple
    apple_block:            .short 0
    # Initialize last time with 0
    last_time:              .long 0
    # Initialize direction with 0 (= right)
    direction:              .byte 0
    # Initialize last known direction to avoid 180-degree turns
    last_direction:         .byte 0
    # Initialize no-last-remove with 0 (remove last block normally)
    no_last_remove:         .byte 0
    # Difficulty level
    difficulty:             .quad 5

    # Current score
    score:                  .quad 0
    # Best scores
    first_score:            .quad 0
    second_score:           .quad 0
    third_score:            .quad 0

    # Mix_Chunk pointer for sound
    beep_pointer:             .quad 0

    # Gameover screen strings
    # Score = "Score: " + 4-digit decimal + "\0" - 12 bytes
    player_score:           .skip 12
    # First = "1: " + 4-digit decimal + "\0": - 8 bytes
    first_place:            .skip 8
    # Second = "2: " + 4-digit decimal + "\0": - 8 bytes
    second_place:           .skip 8
    # Third = "3: " + 4-digit decimal + "\0": - 8 bytes
    third_place:            .skip 8

    # New game flag
    newgame_flag:           .byte 0


# Zero-initialized memory areas
.bss
    # Active game area is 364 blocks (26 x 14)
    # In addition to this, there are one block wide borders
    # So total area is 28 x 16 blocks = 672 x 384 px (scaled up x8)
    # A block needs 2 bytes of storage
    # Maximum length of snake is the same as game area, plus 1 word for queue:
    snakequeue:             .skip 730

    # An array to represent possible spaces for an apple
    # 0 if free, 1 if not
    # This is maintained in every tick
    block_occupied:         .skip 364

    # A stack which is used for the apple lottery
    apple_lottery_stack:    .skip 728


# Constants and program code
.text
    # For displaying data in terminal
    scorestr:               .asciz "Score: %ld\n"
    diffstr:                .asciz "Difficulty: %ld\n"

    # Window
    window_title:           .asciz "Snake"      # window title
    .equ window_height,     384                 # window height is 384
    .equ window_width,      672                 # window width is 672
    .equ window_x,          536805376           # undefined
    .equ window_y,          536805376           # undefined

    .equ bg_r,              190                 # background red
    .equ bg_g,              195                 # background green
    .equ bg_b,              40                  # background blue
    .equ bg_a,              255                 # background opacity

    .equ red,               128                 # drawing red
    .equ green,             114                 # drawing green
    .equ blue,              23                  # drawing blue
    .equ alpha,             255                 # drawing opacity

    # Starting position: third row, fourth column = 55
    start_position:         .word 55

    # game over display
    font:                   .asciz "files/nokiafc22.ttf"
    .equ font_size,         40
    fontcolor:              .byte 128
                            .byte 114
                            .byte 23
                            .byte 255

    .equ score_x,           200                 # "Score: XXXX"
    .equ score_y,           30

    .equ first_x,           255                 # "1: XXXX"
    .equ first_y,           110

    .equ second_x,          245                 # "2: XXXX"
    .equ second_y,          160

    .equ third_x,           245                 # "3: XXXX"
    .equ third_y,           210

    newgame_text:           .asciz "New game? (y/n)"
    .equ newgame_x,         140
    .equ newgame_y,         290

    # Sound
    mode:                   .string "rb"        # Mode rb = read as binary
    soundfile:              .string "files/beep.wav"
    .equ frequency,         22050



.macro CONVERT_TO_STRING
    # Convert digits one by one (max 4 digits here...)
    # 4 bytes, pad with zeros, insert at [ptr...ptr+3]
    movq    $10, %r10
    movq    $3, %rcx
1:
    xorq    %rdx, %rdx
    divq    %r10
    addq    $0x30, %rdx
    movb    %dl, (%r9, %rcx, 1)
    decq    %rcx
    cmpq    $0, %rcx
    jge     1b
.endm


.macro INIT_STRINGS
    # Build strings needed for gameover screen
    # Player score
    xorq    %rax, %rax
    movb    $'S', player_score(%rax)
    incq    %rax
    movb    $'c', player_score(%rax)
    incq    %rax
    movb    $'o', player_score(%rax)
    incq    %rax
    movb    $'r', player_score(%rax)
    incq    %rax
    movb    $'e', player_score(%rax)
    incq    %rax
    movb    $':', player_score(%rax)
    incq    %rax
    movb    $' ', player_score(%rax)
    incq    %rax
    movb    $'0', player_score(%rax)
    incq    %rax
    movb    $'0', player_score(%rax)
    incq    %rax
    movb    $'0', player_score(%rax)
    incq    %rax
    movb    $'0', player_score(%rax)
    incq    %rax
    movb    $0, player_score(%rax)
    # First place
    xorq    %rax, %rax
    movb    $'1', first_place(%rax)
    incq    %rax
    movb    $':', first_place(%rax)
    incq    %rax
    movb    $' ', first_place(%rax)
    incq    %rax
    movb    $'0', first_place(%rax)
    incq    %rax
    movb    $'0', first_place(%rax)
    incq    %rax
    movb    $'0', first_place(%rax)
    incq    %rax
    movb    $'0', first_place(%rax)
    incq    %rax
    movb    $0, first_place(%rax)
    # Second place
    xorq    %rax, %rax
    movb    $'2', second_place(%rax)
    incq    %rax
    movb    $':', second_place(%rax)
    incq    %rax
    movb    $' ', second_place(%rax)
    incq    %rax
    movb    $'0', second_place(%rax)
    incq    %rax
    movb    $'0', second_place(%rax)
    incq    %rax
    movb    $'0', second_place(%rax)
    incq    %rax
    movb    $'0', second_place(%rax)
    incq    %rax
    movb    $0, second_place(%rax)
    # Third place
    xorq    %rax, %rax
    movb    $'3', third_place(%rax)
    incq    %rax
    movb    $':', third_place(%rax)
    incq    %rax
    movb    $' ', third_place(%rax)
    incq    %rax
    movb    $'0', third_place(%rax)
    incq    %rax
    movb    $'0', third_place(%rax)
    incq    %rax
    movb    $'0', third_place(%rax)
    incq    %rax
    movb    $'0', third_place(%rax)
    incq    %rax
    movb    $0, third_place(%rax)
.endm


.macro PRINT_HISCORE score, string, x, y

    # Insert the hiscore decimal value to string
    movq    \string, %r9
    # Magic number: the number goes in bytes 3-6 of this string
    addq    $3, %r9
    movq    \score, %rax
    CONVERT_TO_STRING

    # prepare texture
    movq    %r12, %rdi
    movq    \string, %rsi
    movl    fontcolor, %edx
    call    TTF_RenderText_Solid            # returns a pointer to a surface.
    movq    %rax, %r14                      # Save it in r14

    # create texture
    movq    %r13, %rdi                      # renderer
    movq    %r14, %rsi                      # surface
    call    SDL_CreateTextureFromSurface    # returns a pointer to a texture.
    movq    %rax, %r15                      # Save it in r15


    movl    \x, (%rsp)                  # Init dstrect
    movl    \y, 4(%rsp)
    movl    $0, 8(%rsp)
    movl    $0, 12(%rsp)

    movq    %r15, %rdi                  # texture
    movl    $0, %esi
    movl    $0, %edx
    leaq    8(%rsp), %rcx               # Stack slot for width
    leaq    12(%rsp), %r8               # Stack slot for height
    call    SDL_QueryTexture            # query the attributes of the texture

    # copy a portion of the texture to the current rendering target
    movq    %r13, %rdi                  # renderer
    movq    %r15, %rsi                  # texture
    movq    $0, %rdx                    # srcrect = NULL, entire texture
    movq    %rsp, %rcx                  # dstrect in stack
    call    SDL_RenderCopy

    # Free surface and texture
    movq    %r15, %rdi
    call    SDL_DestroyTexture
    movq    %r14, %rdi
    call    SDL_FreeSurface
.endm


.macro DRAW_BLANK_SCREEN
    # Set color for background
    # SDL_SetRenderDrawColor wants the renderer, r, g, b, and a
    movq    %r13, %rdi
    movl    $bg_r, %esi
    movl    $bg_g, %edx
    movl    $bg_b, %ecx
    movl    $bg_a, %r8d
    call    SDL_SetRenderDrawColor

    # Draw background
    movq    %r13, %rdi
    call    SDL_RenderClear

    # Set color for foreground
    movq    %r13, %rdi
    movl    $red, %esi
    movl    $green, %edx
    movl    $blue, %ecx
    movl    $alpha, %r8d
    call    SDL_SetRenderDrawColor

    # Draw 8 pixel borders 8 pixels from the edges
    # Top border:
    movq    %r13, %rdi
    movl    $8, (%rsp)                  # x
    movl    $8, 4(%rsp)                 # y
    movl    $656, 8(%rsp)               # w
    movl    $8, 12(%rsp)                # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the rectangle
    # Bottom border:
    movq    %r13, %rdi
    movl    $8, (%rsp)                  # x
    movl    $368, 4(%rsp)               # y
    movl    $656, 8(%rsp)               # w
    movl    $8, 12(%rsp)                # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the rectangle
    # Left border:
    movq    %r13, %rdi
    movl    $8, (%rsp)                  # x
    movl    $16, 4(%rsp)                # y
    movl    $8, 8(%rsp)                 # w
    movl    $352, 12(%rsp)              # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the rectangle
    # Right border:
    movq    %r13, %rdi
    movl    $656, (%rsp)                # x
    movl    $16, 4(%rsp)                # y
    movl    $8, 8(%rsp)                 # w
    movl    $352, 12(%rsp)              # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the rectangle
.endm


.macro INIT_SNAKE
    # Reset the direction
    movb    $0, direction
    movb    $0, last_direction
    # The snakequeue variable should contain block numbers.
    # The queue head is in r14, tail in r15
    movq    $0, %r14                    # HEAD = oldest block on screen
    movq    $0, %r15                    # TAIL = newest block on screen

    xorq    %rcx, %rcx
    movw    start_position, %cx         # Start drawing from the last block
    subw    $2, %cx                     # Three long, facing right
    ENQUEUE %cx
    incw    %cx
    ENQUEUE %cx
    incw    %cx
    ENQUEUE %cx
    # snakequeue should now contain a 3-block snake
.endm


.macro ENQUEUE block
    leaq    snakequeue(, %r15d, 2), %rdx
    movw    \block, (%rdx)                      # Add block to the end
    incl    %r15d                               # Update tail
    cmpl    $364, %r15d                         # Check for overflow
    jge     0f
    jmp     1f
0:
    movl    $0, %r15d                           # Start from beginning
1:
    xorq    %rax, %rax
    movw    \block, %ax
    movb    $1, block_occupied(%rax)            # Reserve the block
.endm


.macro DEQUEUE
    xorq    %rax, %rax
    leaq    snakequeue(, %r14d, 2), %rdx
    movw    (%rdx), %ax
    incl    %r14d                               # Update head
    cmpl    $364, %r14d                         # Check for overflow
    jge     0f
    jmp     1f
0:
    movl    $0, %r14d                           # Start from beginning
1:
    movb    $0, block_occupied(%rax)            # Free the block for use
.endm


.macro DISPATCH_APPLE
    # Set the apple_block to be some free block on the game area
    # Here we need some randomness

    # Check how many blocks are free and which ones they are
    xorq    %rcx, %rcx
    xorq    %rax, %rax
    xorq    %rbx, %rbx
6:
    cmpq    $363, %rcx
    jg      8f
    movb    block_occupied(%rcx), %al
    test    %al, %al
    jz      7f
    incq    %rcx
    jmp     6b
7:
    movw    %cx, apple_lottery_stack(, %rbx, 2)
    incq    %rbx
    incq    %rcx
    jmp     6b

    # Now we should have the number of free blocks in %rbx, and the
    # actual block numbers in apple_lottery_stack(0...%rbx-1).
8:
    call    SDL_GetTicks
    movq    %rax, %rdx
    call    random
    addq    %rdx, %rax
    # A random value is in %rax now
    xorq    %rdx, %rdx
    divq    %rbx
    # A random value between 0...%rbx-1 should be in %rdx now
    xorq    %rcx, %rcx
    movw    apple_lottery_stack(, %rdx, 2), %cx
    movw    %cx, apple_block
.endm


.macro DRAW_SNAKE_BLOCK block
    # This macro draws one 24 x 24 pixel block of snake
    # Decoding of coordinates:
    # Keep subbing 26 from the block number until it's under 26
    # Number of these substractions is y (unscaled)
    # The remaining number is x (unscaled)
    movw    \block, %ax
    movl    $0, %r8d
    1:
    cmpw    $26, %ax
    jl      2f                          # Jump forwards in macro
    subw    $26, %ax
    addl    $24, %r8d
    jmp     1b                          # Jump backwards in macro
    2:
    # Scaling: xScaled = 24 + 24*x, yScaled = 24 + 24*y
    movl    $24, %ecx
    mull    %ecx
    addw    $24, %ax
    addl    $24, %r8d

    movq    %r13, %rdi                  # renderer
    movw    %ax, (%rsp)                 # x
    movl    %r8d, 4(%rsp)               # y
    movl    $24, 8(%rsp)                # w
    movl    $24, 12(%rsp)               # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the block
.endm


.macro DRAW_APPLE block
    # This macro draws one 24 x 24 pixel block of an apple using 4 8x8 blocks
    # Decoding of coordinates:
    # Keep subbing 26 from the block number until it's under 26
    # Number of these substractions is y (unscaled)
    # The remaining number is x (unscaled)
    movw    \block, %ax
    movl    $0, %r8d
    1:
    cmpw    $26, %ax
    jl      2f                          # Jump forwards in macro
    subw    $26, %ax
    addl    $24, %r8d
    jmp     1b                          # Jump backwards in macro
    2:
    # Scaling: xScaled = 24 + 24*x, yScaled = 24 + 24*y
    movl    $24, %ecx
    mull    %ecx
    addw    $24, %ax                    # x
    addl    $24, %r8d                   # y
    movw    %ax, (%rsp)                 # put x on stack
    movl    %r8d, 4(%rsp)               # put y on stack

    # top block
    addw    $8, (%rsp)                  # x
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                 # w
    movl    $8, 12(%rsp)                # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block

    # left block
    subw    $8, (%rsp)                  # restore x
    addw    $8, 4(%rsp)                 # y + 8
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                 # w
    movl    $8, 12(%rsp)                # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block

    # right block
    addw    $16, (%rsp)                 # x + 16
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                 # w
    movl    $8, 12(%rsp)                # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block

    # bottom block
    subw    $8, (%rsp)                  # x + 8
    addw    $8, 4(%rsp)                 # y + 16
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                 # w
    movl    $8, 12(%rsp)                # h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block
.endm


.macro DRAW_GAME_TICK
    # Each game tick should:
    # A) check the direction,
    # B) detect possible crash,
    # C) set a new first block for the snake,
    # D) remove the last block if the snake didn’t eat in the last loop,
    # E) set a new apple and play a beep if it did eat now,
    # F) update the screen.

    movl    %r15d, %eax
    decl    %eax
    cmpl    $0, %eax                        # In case of wrap, go back to end
    jl      1f
0:
    xorq    %rbx, %rbx
    leaq    snakequeue(, %eax, 2), %rdx
    movw    (%rdx), %bx                     # This is the current first block
    movb    direction, %al                  # Where are we going
    jmp     2f
1:
    movl    $363, %eax
    jmp     0b
2:

    # A) Check direction and save it for later use
    movb    %al, last_direction
    cmpb    $3, %al                         # Up
    je      6f
    cmpb    $2, %al                         # Down
    je      7f
    cmpb    $1, %al                         # Left
    je      8f
    cmpb    $0, %al                         # Right
    je      9f
    jmp     1f

    # B) Labels 6-9: check if illegal direction for this first block in %bx
    # Forward to the_end if it is
    # Otherwise calculate new position and let through
6:
    cmpw    $26, %bx                        # Top row, 0-25
    jl      the_end
    subw    $26, %bx
    jmp     0f
7:
    cmpw    $337, %bx                       # Bottom row, 338-363
    jg      the_end
    addw    $26, %bx
    jmp     0f
8:
    xorq    %rdx, %rdx
    xorq    %rax, %rax
    movq    %rbx, %rax
    movq    $26, %rsi                       # Left column, multiples of 26
    divq    %rsi
    cmpq    $0, %rdx                        # Expect remainder to not be 0
    je      the_end
    subw    $1, %bx
    jmp     0f
9:
    xorq    %rdx, %rdx
    xorq    %rax, %rax
    movq    %rbx, %rax
    movq    $26, %rsi                       # Right column, multiples of 26
    divq    %rsi                            # plus 25
    cmpq    $25, %rdx                       # Expect remainder to not be 25
    je      the_end
    addw    $1, %bx
    jmp     0f

    # C) Remove the last block if we didn't eat during the last tick
    # If we did, just clear the no_last_remove flag.
0:
    xorq    %rax, %rax
    movb    no_last_remove, %al
    cmpb    $0, %al
    je      1f
    jmp     2f
1:
    # Didn't eat, remove the last block
    DEQUEUE
    jmp     6f
2:
    # Did eat, clear the flag
    movb    $0, no_last_remove
6:

    # D) Check the new first block and see if there was already a snake block
    # Forward to the_end if there was
    # Otherwise ENQUEUE and let through
    xorq    %rax, %rax
    movb    block_occupied(%rbx), %al
    cmpb    $0, %al
    jne     the_end
    ENQUEUE %bx

    # E) Check for apple under the new first block
    # Should there be one, dispatch a new one, play a beep, and raise
    # the no_last_remove flag for next tick
    xorq    %rcx, %rcx
    movw    apple_block, %cx                # Apple location
    cmpw    %cx, %bx                        # Match with first block
    jne     2f
    DISPATCH_APPLE

    # Beep
    movq	beep_pointer, %rdi 				# Pointer to the Mix_music
    movl	$1, %esi 						# Number of times to play the music
	call	Mix_PlayMusic

    # Increment score
    movw    difficulty, %cx
    addw    %cx, score
    movb    $1, no_last_remove
2:

    # F) Update screen
    # Forall (snakeblock) DRAW_SNAKE_BLOCK
    # So: starting from the last block (queue head, oldest on screen),
    # roam the snakequeue and draw all blocks.

    DRAW_BLANK_SCREEN
    movl    %r14d, %ebx
3:
    xorq    %rcx, %rcx
    leaq    snakequeue(, %ebx, 2), %rdx
    movw    (%rdx), %cx
    DRAW_SNAKE_BLOCK %cx
    incl    %ebx
    cmpl    $364, %ebx
    jge     4f
    cmpl    %r15d, %ebx
    je      5f
    jmp     3b
4:
    movl    $0, %ebx
    cmpl    %r15d, %ebx
    je      5f
    jmp     3b
5:
    # DRAW_APPLE
    xorq    %rcx, %rcx
    movw    apple_block, %cx
    DRAW_APPLE %cx

    # Refresh the screen
    movq    %r13, %rdi
    call    SDL_RenderPresent
.endm











.globl main

main:
    # Init basepointer
    pushq   %rbp
    movq    %rsp, %rbp

    # get command line args : set difficulty if between 1-9
    # corresponds to second arg: argv[1]
    cmpq    $2, %rdi			# argc below 2 = no args
    jl      no_args
    xorq    %rbx, %rbx
    movq    8(%rsi), %rcx		# argv is in %rcx now
    movb    (%rcx), %bl			# The first char of arguments
    subq    $0x30, %rbx			# Convert to decimal


    cmpq    $1, %rbx 			# Check if in range
    jl      no_args
    cmpq    $9, %rbx
    jg      no_args
    movq    %rbx, difficulty


no_args:
    movq    $diffstr, %rdi		# first arg for printf
    movq    difficulty, %rsi	# Display difficulty in terminal
    movq    $0, %rax			# no vectors
    call    printf				# print

    movl    $0x7231, %edi		# Magic number: SDL_INIT_EVERYTHING = 0x7231
    # Init SDL
    call    SDL_Init

    # Init sound
    movl    $frequency, %edi	# Frequency in Hz
    movl    $0x8010, %esi       # Magic number: MIX_DEFAULT_FORMAT = 0x8010
    movl    $2, %edx            # Channels, 2 for stereo
    movl    $4096, %ecx         # Chunksize: bytes used for output sample
    call    Mix_OpenAudio       # Returns 0 on success, -1 on errors

	

    movq	$soundfile, %rdi 	# Sound file
	call	Mix_LoadMUS 		# Returns a pointer to a Mix_Music
	movq	%rax, beep_pointer	# Save pointer in variable

    # Create window
    # Parameters go to rdi, rsi, rdx, rcx, r8 and r9;
    # SDL_CreateWindow wants window title, x, y, width, height and flags
    # Magic number: SDL_WINDOW_OPENGL = 2
    movq    $window_title, %rdi
    movl    $window_x, %esi
    movl    $window_y, %edx
    movl    $window_width, %ecx
    movl    $window_height, %r8d
    movl    $2, %r9d
    call    SDL_CreateWindow
    # This returns a pointer to a window. Save it in r12 for use:
    movq    %rax, %r12

    # Use stack to store the needed rectangle structures as x, y, w, h
    subq    $16, %rsp

    # Initialize hiscores
    movq    $0, first_score
    movq    $0, second_score
    movq    $0, third_score

game_start:
    # Create renderer
    # SDL_CreateRenderer wants the window, index, and flags
    # Magic number: SDL_RENDER_ACCELERATED = 2
    # Magic number: First suitable rendering driver = -1
    movq    %r12, %rdi
    movl    $-1, %esi
    movl    $2, %edx
    call    SDL_CreateRenderer
    # This returns a pointer to a renderer. Save it in r13:
    movq    %rax, %r13

    # Init occupied blocks
    movq    $364, %rcx
block_init_loop:
    decq    %rcx
    movb    $0, block_occupied(, %rcx, 1)
    cmpq    $0, %rcx
    jne     block_init_loop

    # Init Score
    movq    $0, score
    # Init starting time
    movl    $0, last_time
    # Init game elements and draw the first frame
    INIT_SNAKE
    DISPATCH_APPLE
    DRAW_GAME_TICK

loop:
    # Main game loop runs fast to detect keycodes
    # Each game loop should update the pressed keys and
    # every #n time call the actual game tick macro
    # (#n depends on difficulty level)

    # Get difficulty
    movq    difficulty, %rcx
    movq    $1000, %rax
    xorq    %rdx, %rdx
    divq    %rcx
    movq    %rax, %rbx

    # Get time
    movq    $0, %rdi
    call    SDL_GetTicks
    # Compare to last time
    movl    %eax, %ecx
    subl    %ebx, %ecx
    cmpl    last_time, %ecx
    jge     gametick
    jmp     no_gametick

    # Use rbx to store gametick flag
gametick:
    movl    $1, %ebx
    # Update last gametick draw time
    movl    %eax, last_time
    jmp     eventcheck

no_gametick:
    movl    $0, %ebx
    jmp     eventcheck

eventcheck:
    # Pump events
    movq    $0, %rdi
    call    SDL_PumpEvents
    # Check keycode table
    movq    $0, %rdi
    call    SDL_GetKeyboardState
    # Reference to keycode array is now in rax
    # Magic number: SDL_SCANCODE_RIGHT = 79
    # Magic number: SDL_SCANCODE_LEFT = 80
    # Magic number: SDL_SCANCODE_DOWN = 81
    # Magic number: SDL_SCANCODE_UP = 82
    # Magic number: SDL_SCANCODE_ESCAPE = 41
    cmpb    $1, 79(%rax)
    je      right_pressed
    cmpb    $1, 80(%rax)
    je      left_pressed
    cmpb    $1, 81(%rax)
    je      down_pressed
    cmpb    $1, 82(%rax)
    je      up_pressed
    cmpb    $1, 41(%rax)
    je      the_end
    jmp     proceed

    # Update direction vector if it isn't a 180 degree turn
right_pressed:
    movb    last_direction, %al
    cmpb    $1, %al
    je      proceed
    movb    $0, direction
    jmp     proceed
left_pressed:
    movb    last_direction, %al
    cmpb    $0, %al
    je      proceed
    movb    $1, direction
    jmp     proceed
down_pressed:
    movb    last_direction, %al
    cmpb    $3, %al
    je      proceed
    movb    $2, direction
    jmp     proceed
up_pressed:
    movb    last_direction, %al
    cmpb    $2, %al
    je      proceed
    movb    $3, direction
    jmp     proceed





proceed:
    # When time is right, execute a game tick
    # Compare flag and if it's set, execute
    cmpl    $1, %ebx
    je      do_gametick
    jmp     loop

do_gametick:
    DRAW_GAME_TICK
    jmp     loop



quit:
    # Destroy window
    movq    %r12, %rdi
    call    SDL_DestroyWindow

    call    Mix_CloseAudio          # Shutdown and close the mixer API

    # Shut down SDL
    movq    $0, %rdi
    call    SDL_Quit
    movq    score, %rsi             # Display score in terminal
    movq    $scorestr, %rdi         # first arg for printf
    movq    $0, %rax                # again no vectors
    call    printf                  # print

    # Cleanup
    movq    %rbp, %rsp
    popq    %rbp
    # Exit code 0
    movq    $0, %rdi
    call    exit


# **************************************************************************** #
#
#   Display hiscores and choose to play again/exit
#
# **************************************************************************** #
the_end:

    pushq   %r12                    # Put these to safety
    pushq   %r13
    pushq   %r14
    pushq   %r15
    pushq   %rbx
    pushq   %rdi
    pushq   %rsi

    pushq   %rbp                    # New "stackframe"
    movq    %rsp, %rbp

# **************************************************************************** #

    # Destroy old renderer and create a new one for this screen
    movq    %r13, %rdi
    call    SDL_DestroyRenderer
    # Create renderer
    # SDL_CreateRenderer wants the window, index, and flags
    # Magic number: SDL_RENDER_ACCELERATED = 2
    # Magic number: First suitable rendering driver = -1
    movq    %r12, %rdi
    movl    $-1, %esi
    movl    $2, %edx
    call    SDL_CreateRenderer
    # This returns a pointer to a renderer. Save it in r13:
    movq    %rax, %r13


    # Check if we made the hiscores
    movq    score, %rax

    movq    first_score, %rdx
    cmpq    %rdx, %rax                  # First place?
    jg      st_place

    movq    second_score, %rdx
    cmpq    %rdx, %rax                  # Second place?
    jg      nd_place

    movq    third_score, %rdx
    cmpq    %rdx, %rax                  # Third place?
    jg      rd_place

    jmp     gameover_screen

st_place:
    movq    second_score, %rax          # Move 2nd to 3rd
    movq    %rax, third_score

    movq    first_score, %rax           # Move 1st to 2nd
    movq    %rax, second_score

    movq    score, %rax                 # Replace 1st
    movq    %rax, first_score

    jmp     gameover_screen

nd_place:
    movq    second_score, %rax          # Move 2nd to 3rd
    movq    %rax, third_score

    movq    score, %rax                 # Replace 2nd
    movq    %rax, second_score

    jmp     gameover_screen

rd_place:
    movq    score, %rax                 # Replace 3rd
    movq    %rax, third_score

    jmp     gameover_screen

gameover_screen:

    # Initialize gameover strings
    INIT_STRINGS

    # init ttf
    call    TTF_Init

    # Set color for background
    # SDL_SetRenderDrawColor wants the renderer, r, g, b, and a
    movq    %r13, %rdi
    movl    $bg_r, %esi
    movl    $bg_g, %edx
    movl    $bg_b, %ecx
    movl    $bg_a, %r8d
    call    SDL_SetRenderDrawColor

    # Clear background
    movq    %r13, %rdi
    call    SDL_RenderClear

    # create font
    movq    $font, %rdi
    movl    $font_size, %esi
    call    TTF_OpenFont                # returns a pointer to a font.
    movq    %rax, %r12                  # Save it in r12

    subq    $16, %rsp                   # Space for dstrect






    #
    # "Score: {{score}}"
    #

    # Insert score to player_score string
    movq    $player_score, %r9
    # Magic number: the number goes in bytes 7-11 of this string
    addq    $7, %r9
    movq    score, %rax
    CONVERT_TO_STRING


    # prepare texture
    movq    %r12, %rdi
    movq    $player_score, %rsi
    movl    fontcolor, %edx
    call    TTF_RenderText_Solid            # returns a pointer to a surface.
    movq    %rax, %r14                      # Save it in r14

    # create texture
    movq    %r13, %rdi                      # renderer
    movq    %r14, %rsi                      # surface
    call    SDL_CreateTextureFromSurface    # returns a pointer to a texture.
    movq    %rax, %r15                      # Save it in r15


    movl    $score_x, (%rsp)            # Init dstrect
    movl    $score_y, 4(%rsp)
    movl    $0, 8(%rsp)
    movl    $0, 12(%rsp)

    movq    %r15, %rdi                  # texture
    movl    $0, %esi                    # these params not needed
    movl    $0, %edx
    leaq    8(%rsp), %rcx               # Stack slot for width
    leaq    12(%rsp), %r8               # Stack slot for height
    call    SDL_QueryTexture            # query the attributes of the texture

    # copy the texture to the current rendering target
    movq    %r13, %rdi                  # renderer
    movq    %r15, %rsi                  # texture
    movq    $0, %rdx                    # srcrect = NULL, entire texture
    movq    %rsp, %rcx                  # dstrect in stack
    call    SDL_RenderCopy

    # Free surface and texture
    movq    %r15, %rdi
    call    SDL_DestroyTexture
    movq    %r14, %rdi
    call    SDL_FreeSurface



    # Print hiscores
    PRINT_HISCORE first_score, $first_place, $first_x, $first_y
    PRINT_HISCORE second_score, $second_place, $second_x, $second_y
    PRINT_HISCORE third_score, $third_place, $third_x, $third_y





    #
    # "New game? (y/n)"
    #

    # prepare texture
    movq    %r12, %rdi
    movq    $newgame_text, %rsi
    movl    fontcolor, %edx
    call    TTF_RenderText_Solid            # returns a pointer to a surface.
    movq    %rax, %r14                      # Save it in r14

    # create texture
    movq    %r13, %rdi                      # renderer
    movq    %r14, %rsi                      # surface
    call    SDL_CreateTextureFromSurface    # returns a pointer to a texture.
    movq    %rax, %r15                      # Save it in r15


    movl    $newgame_x, (%rsp)          # Init dstrect
    movl    $newgame_y, 4(%rsp)
    movl    $0, 8(%rsp)
    movl    $0, 12(%rsp)

    movq    %r15, %rdi                  # texture
    movl    $0, %esi
    movl    $0, %edx
    leaq    8(%rsp), %rcx               # Stack slot for width
    leaq    12(%rsp), %r8               # Stack slot for height
    call    SDL_QueryTexture            # query the attributes of the texture

    # copy  the texture to the current rendering target
    movq    %r13, %rdi                  # renderer
    movq    %r15, %rsi                  # texture
    movq    $0, %rdx                    # srcrect = NULL, entire texture
    movq    %rsp, %rcx                  # dstrect in stack
    call    SDL_RenderCopy

    # Free surface and texture
    movq    %r15, %rdi
    call    SDL_DestroyTexture
    movq    %r14, %rdi
    call    SDL_FreeSurface






    # update the screen with any rendering performed
    movq    %r13, %rdi                  # renderer
    call    SDL_RenderPresent

    # check if user wants to exit
loop_gameover:
    movq    $0, %rdi
    call    SDL_PumpEvents
    # Check keycode table
    movq    $0, %rdi
    call    SDL_GetKeyboardState
    # SDL_SCANCODE_Y = 28
    cmpb    $1, 28(%rax)
    je      new_game
    # SDL_SCANCODE_N = 17
    cmpb    $1, 17(%rax)
    je      no_new_game
    jmp     loop_gameover

new_game:
    movb    $1, newgame_flag
    jmp     end_gameover

no_new_game:
    movb    $0, newgame_flag
    jmp     end_gameover


end_gameover:
    # Close font
    movq    %r12, %rdi
    call    TTF_CloseFont
    call    TTF_Quit
    # Destroy renderer
    movq    %r13, %rdi
    call    SDL_DestroyRenderer

# **************************************************************************** #

    movq    %rbp, %rsp              # Tear down stackframe
    popq    %rbp

    popq    %rsi                    # Restore old regs
    popq    %rdi
    popq    %rbx
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12

    movb    newgame_flag, %al       # Quit or play again
    test    %al, %al
    jnz     game_start
    jmp     quit
