# Variables
.data
    # Contains the block number for the current apple
    apple_block: .short 0
    # Initialize last time with 0
    last_time: .long 0
    # Initialize direction with 0 (= right)
    direction: .byte 0


# Zero-initialized memory areas
.bss
    # Active game area is 364 blocks (26 x 14)
    # In addition to this, there are one block wide borders
    # So total area is 28 x 16 blocks = 672 x 384 px (scaled up x8)
    # A block needs 2 bytes of storage
    # Maximum length of snake is the same as game area:
    snakequeue: .skip 728

    # An array to represent possible spaces for an apple
    # 0 if free, 1 if not
    # This is maintained in every tick
    block_occupied: .skip 364
    # A stack which is used for the apple lottery
    apple_lottery_stack: .skip 728


# Constants and program code
.text
    # Window
    window_title: .asciz "Snake"            # window title
    .equ window_height, 384                 # window height is 384
    .equ window_width, 672                  # window width is 672
    .equ window_x, 536805376                # undefined
    .equ window_y, 536805376                # undefined

    .equ bg_r, 190                          # background red
    .equ bg_g, 195                          # background green
    .equ bg_b, 40                           # background blue
    .equ bg_a, 255                          # background opacity

    .equ red, 128                           # drawing red
    .equ green, 114                         # drawing green
    .equ blue, 23                           # drawing blue
    .equ alpha, 255                         # drawing opacity

    # Starting position: third row, fourth column = 55
    start_position: .word 55

    test_str: .asciz "%ld\n"




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
    # The snakequeue variable should contain block numbers.
    # The queue head is in r14, tail in r15
    movl    $0, %r14d
    movl    $0, %r15d

    movw    start_position, %cx
    subw    $2, %cx
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
    movw    \block, %ax
    movb    $1, block_occupied(%rax)            # Reserve the block
.endm


.macro DEQUEUE
    leaq    snakequeue(, %r14d, 2), %rdx
    movw    (%rdx), %ax
    incl    %r14d                               # Update head
    cmpl    $364, %r14d                         # Check for overflow
    jge     0f
    jmp     1f
0:
    movl    $0, r14d                            # Start from beginning
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
    movb    $1, block_occupied(%rcx)            # Reserve the block
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
    movw    %ax, (%rsp)                	# put x on stack
    movl    %r8d, 4(%rsp)              	# put y on stack

    # top block
    addw    $8, (%rsp)                  # x
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                	# w
    movl    $8, 12(%rsp)               	# h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block

    # left block
    subw    $8, (%rsp)                  # restore x
    addw    $8, 4(%rsp)                 # y + 8
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                	# w
    movl    $8, 12(%rsp)               	# h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block

    # right block
    addw    $16, (%rsp)                 # x + 16
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                	# w
    movl    $8, 12(%rsp)               	# h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block

    # bottom block
    subw    $8, (%rsp)                  # x + 8
    addw	$8, 4(%rsp)                 # y + 16
    movq    %r13, %rdi                  # renderer
    movl    $8, 8(%rsp)                	# w
    movl    $8, 12(%rsp)               	# h
    movq    %rsp, %rsi
    call    SDL_RenderFillRect          # Fill the the block

.endm


.macro DRAW_GAME_TICK
    # Each game tick should:
    # A) check the direction,
    # B) detect possible crash,
    # C) set a new head for the snake,
    # D) remove the tail if the snake didn’t eat in the last loop,
    # E) set a new apple and play a beep if it did eat now,
    # F) update the screen.

<<<<<<< Updated upstream
    leaq    snakequeue(, %r14d, 2), %rdx
    movw    (%rdx), %ax                     # This is the current head


=======
    movl    %r15d, %eax
    decl    %eax
    leaq    snakequeue(, %eax, 2), %rdx
    movw    (%rdx), %bx                     # This is the current head
    movb    direction, %al                  # Where are we going

    # A) Check direction
    cmpb    $3, %al                         # Up
    je      6f
    cmpb    $2, %al                         # Down
    je      7f
    cmpb    $1, %al                         # Left
    je      8f
    cmpb    $0, %al                         # Right
    je      9f
    jmp     1f

    # B) Labels 6-9: check if illegal direction for this head in %bx
    # Forward to the_end if it is
    # Otherwise calculate new position and let through
6:
    cmpw    $26, %bx                    # Top row, 0-25
    jl      the_end
    subw    $26, %bx
    jmp     0f
7:
    cmpw    $337, %bx                   # Bottom row, 338-363
    jg      the_end
    addw    $26, %bx
    jmp     0f
8:
    xorq    %rdx, %rdx
    xorq    %rax, %rax
    movq    %rbx, %rax
    movq    $26, %rsi                   # Left column, multiples of 26
    divq    %rsi
    cmpq    $0, %rdx                    # Expect remainder to not be 0
    je      the_end
    subw    $1, %bx
    jmp     0f
9:
    xorq    %rdx, %rdx
    xorq    %rax, %rax
    movq    %rbx, %rax
    movq    $26, %rsi                   # Right column, multiples of 26
    divq    %rsi                        # plus 25
    cmpq    $25, %rdx                   # Expect remainder to not be 25
    je      the_end
    addw    $1, %bx
    jmp     0f

    # C) Remove tail if we didn't eat during the last tick
    # If we did, just clear the no_tail_remove flag.
0:
    xorq    %rax, %rax
    movb    no_tail_remove, %al
    cmpb    $0, %al
    je      1f
    jmp     2f
1:
    # Didn't eat, remove tail
    DEQUEUE
    jmp     6f
2:
    # Did eat, clear the flag
    movb    $0, no_tail_remove
6:

    # D) Check the new head and see if there was already a snake block
    # Forward to the_end if there was
    # Otherwise ENQUEUE and let through
    xorq    %rax, %rax
    movb    block_occupied(%rbx), %al
    cmpb    $0, %al
    jne     the_end
    ENQUEUE %bx

    # E) Check for apple under the new head
    # Should there be one, dispatch a new one, play a beep, and raise
    # the no_tail_remove flag for next tick
    movw    apple_block, %cx                # Apple location
    cmpw    %cx, %bx                        # Match with head
    jne     2f
    movq    $1, %rax
    DISPATCH_APPLE
    movq    $7, %rdi
    call    putchar                         # Beep
    movb    $1, no_tail_remove
2:
>>>>>>> Stashed changes

    # F) Update screen
    # Forall (snakeblock) DRAW_SNAKE_BLOCK
    # So: starting from the last block (queue head, oldest on screen),
    # roam the snakequeue and draw all blocks.

    DRAW_BLANK_SCREEN
    movl    %r14d, %ebx
3:
    leaq    snakequeue(, %ebx, 2), %rdx
    movw    (%rdx), %cx
    DRAW_SNAKE_BLOCK    %cx
    incl    %ebx
    cmpl    $364, %ebx
    jge     4f
    cmpl    %r15d, %ebx
    jge     5f
    jmp     3b
4:
    movl    $0, %ebx
    jmp     3b
5:
    # DRAW_APPLE
	xorq    %rcx, %rcx
	movw    apple_block, %cx
	DRAW_APPLE    %cx
.endm











.globl main

main:
    # Init basepointer
    pushq   %rbp
    movq    %rsp, %rbp

    # get command line args : put difficulty into r15
    # corresponds to second arg: argv[1]
    movq   8(%rsi), %r15

    # SDL_INIT_EVERYTHING = 0x7231
    movl	$0x7231, %edi
    # Init SDL
    call	SDL_Init

    # Create window
    # Parameters go to rdi, rsi, rdx, rcx, r8 and r9;
    # SDL_CreateWindow wants window title, x, y, width, height and flags
    # SDL_WINDOW_OPENGL = 0x2
    movq    $window_title, %rdi
    movl    $window_x, %esi
    movl    $window_y, %edx
    movl    $window_width, %ecx
    movl    $window_height, %r8d
    movl    $0x2, %r9d
    call    SDL_CreateWindow
    # This returns a pointer to a window. Save it in r12 for use:
    movq    %rax, %r12

    # Create renderer
    # SDL_CreateRenderer wants the window, index, and flags
    # SDL_RENDER_ACCELERATED = 0x2
    # First suitable rendering driver = -1
    movq    %r12, %rdi
    movl    $-1, %esi
    movl    $0x2, %edx
    call    SDL_CreateRenderer
    # This returns a pointer to a renderer. Save it in r13:
    movq    %rax, %r13

    # Use stack to store the needed rectangle structures as x, y, w, h
    subq    $16, %rsp

    DRAW_BLANK_SCREEN
    INIT_SNAKE
    DISPATCH_APPLE
    DRAW_GAME_TICK
    movq    %r13, %rdi
    call    SDL_RenderPresent


loop:
    # Main game loop runs fast to detect keycodes
    # Each game loop should update the pressed keys and
    # every #n time call the actual game tick macro
    # (#n depends on difficulty level)

    # Get time
    movq    $0, %rdi
    call    SDL_GetTicks
    # Compare to last time
    movl    %eax, %ecx
    subl    $1000, %ecx
    cmpl    last_time, %ecx
    jge     gametick
    jmp     no_gametick

    # Use rbx to store gametick flag
gametick:
    movl    $1, %ebx
    movl    %eax, last_time                 # Update last time
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
    # SDL_SCANCODE_RIGHT = 79
    # SDL_SCANCODE_LEFT = 80
    # SDL_SCANCODE_DOWN = 81
    # SDL_SCANCODE_UP = 82
    # SDL_SCANCODE_ESCAPE = 41
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

    # Update direction vector
right_pressed:
    movb    $0, direction
    jmp     proceed
left_pressed:
    movb    $1, direction
    jmp     proceed
down_pressed:
    movb    $2, direction
    jmp     proceed
up_pressed:
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
    movq    %r13, %rdi
    call    SDL_RenderPresent
    jmp     loop


the_end:
    # Destroy renderer
    movq    %r13, %rdi
    call    SDL_DestroyRenderer
    # Destroy window
    movq    %r12, %rdi
    call    SDL_DestroyWindow
    # Shut down SDL
    call    SDL_Quit
    # Exit code 0
    movq    $0, %rdi
    call    exit
