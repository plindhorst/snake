# Variables
.data
    # Contains the block number for the current apple
    apple_block: .value 0
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
    # Maximum length of snake is the same as game area, queue needs +1:
    snakequeue: .skip 730


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
    # Starting position: third row, third column, three-block snake
    # The queue head is in r14, tail in r15
    movl    $0, %r14d
    movl    $0, %r15d

    movw    $start_position, %dl
    movw    %dl, snakequeue(%r15d)          # The first snake block
    incw    %r15d                           # Update tail

    subw    $1, %dl
    movw    %dl, snakequeue(0, %r15d, 2)    # 2nd block
    incw    %r15d

    subw    $1, %dl
    movw    %dl, snakequeue(0, %r15d, 2)    # 3rd block
    incw    %r15d
    # snakequeue should now contain a 3-block snake
.endm


.macro DRAW_SNAKE_BLOCK
.endm


.macro DISPATCH_APPLE
    # Set the apple_block to be some free block on the game area
    # Here we need some randomness
    call    clock_gettime
    movq    %r9, %rax
    xor     %rdx, %rdx
    movq    $10, %rcx
    divq    %rcx
    # A random number 0 <= r <= 9 is in rdx now
.endm



.macro DRAW_GAME_TICK
    # Each game tick should:
    # A) search the keycode table for arrow keys,
    # B) detect possible crash,
    # C) set a new head for the snake,
    # D) remove the tail if the snake didn’t eat in the last loop,
    # E) set a new apple and play a beep if it did,
    # F) update the screen.



    # F) Update screen
    movq    %r13, %rdi
    call    SDL_RenderPresent
.endm











.globl main

main:
    # Init basepointer
    pushq   %rbp
    movq    %rsp, %rbp

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
    #INIT_SNAKE
    #DISPATCH_APPLE
    DRAW_GAME_TICK

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
    movb    $1, %bl
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
    movl    $0, direction
    jmp     proceed
left_pressed:
    movl    $1, direction
    jmp     proceed
down_pressed:
    movl    $2, direction
    jmp     proceed
up_pressed:
    movl    $3, direction
    jmp     proceed





proceed:
    # When time is right, execute a game tick
    # Compare flag and if it's set, execute
    cmpl    $1, %ebx
    je      do_gametick
    jmp     loop

do_gametick:
    DRAW_BLANK_SCREEN
    DRAW_GAME_TICK
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
