# Variables
.data


# Zero-initialized memory areas
.bss
    # Screen:
    gamearea: .skip 4032
    # Maximum length of snake is the same as game area, queue needs +1:
    snakequeue: .skip 365


# Constants
.text
    # Starting position: third row, third column, three-block snake
    starthead: .value 765
    startlength: .value 3

    # Window
    window_title: .asciz "Snake"           # window title
    .equ window_height, 384                 # window height is 384
    .equ window_width, 669                  # window width is 672
    .equ window_x, 536805376                # undefined
    .equ window_y, 536805376                # undefined
    


.macro INIT_GAME_AREA
        # Build walls

        # Top row:
        # for i = 85 to 166 (inclusive), write 1 to gamearea[i]
        movq    $85, %rbx
        movq    $166, %rcx
    top_loop:
        movb    $1, gamearea(%rbx)
        incq    %rbx
        cmpq    %rcx, %rbx
        jle     top_loop

        # Bottom row:
        # for i = 3865 to 3946 (inclusive)
        movq    $3865, %rbx
        movq    $3946, %rcx
    bottom_loop:
        movb    $1, gamearea(%rbx)
        incq    %rbx
        cmpq    %rcx, %rbx
        jle     bottom_loop

        # Left column:
        # i = 169, for 44 times, increment by 84
        movq    $169, %rbx
        movq    $44, %rcx
    left_loop:
        movb    $1, gamearea(%rbx)
        addq    $84, %rbx
        decq    %rcx
        cmpq    $0, %rcx
        jg      left_loop

        # Right column:
        # i = 250, for 44 times, increment by 84
        movq    $250, %rbx
        movq    $44, %rcx
    right_loop:
        movb    $1, gamearea(%rbx)
        addq    $84, %rbx
        decq    %rcx
        cmpq    $0, %rcx
        jg      right_loop

.endm


.macro INIT_SNAKE
.endm


.macro DISPATCH_APPLE
    # Here we need some randomness.
    # Apple can be on any block on game area that is not a snake block
    call    clock_gettime
    movq    %r9, %rax
    xor     %rdx, %rdx
    movq    $10, %rcx
    divq    %rcx
    # A random number 0 <= r <= 9 is in rdx now

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

    # Create window:
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







    #INIT_GAME_AREA
    #INIT_SNAKE
    #DISPATCH_APPLE

    #
    # Draw stuff on canvas here
    #




end:
    # For testing: wait for n loops
    incq    %rbx
    # 10^9 makes for a noticeable delay
    cmpq    $2000000000, %rbx
    jl      end


    # Destroy window
    movq    %r12, %rdi
    call    SDL_DestroyWindow
    # Shut down SDL
    call    SDL_Quit
    # Exit code 0
    movq    $0, %rdi
    call    exit
