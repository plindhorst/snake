.data
# starting position: third row, third column, three-block snake
starthead: .value 765
startlength: .value 3

.bss
# screen:
gamearea: .skip 4032
# maximum length of snake is the same as game area, queue needs +1:
snakequeue: .skip 365


.text

timeprint:  .asciz "%ld\n"

.globl main


.macro INIT_GAME_AREA
    # build walls

    # top row:
    # for i = 85 to 166 (inclusive), write 1 to gamearea[i]
    movq    $85, %rbx
    movq    $166, %rcx
top_loop:
    movb    $1, gamearea(%rbx)
    incq    %rbx
    cmpq    %rcx, %rbx
    jle     top_loop

    # bottom row:
    # for i = 3865 to 3946 (inclusive)
    movq    $3865, %rbx
    movq    $3946, %rcx
bottom_loop:
    movb    $1, gamearea(%rbx)
    incq    %rbx
    cmpq    %rcx, %rbx
    jle     bottom_loop

    # left column:
    # i = 169, for 44 times, increment by 84
    movq    $169, %rbx
    movq    $44, %rcx
left_loop:
    movb    $1, gamearea(%rbx)
    addq    $84, %rbx
    decq    %rcx
    cmpq    $0, %rcx
    jg      left_loop

    # right column:
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
    # here we need some randomness.
    # apple can be on any block on game area that is not a snake block
    call    clock_gettime
    movq    %r9, %rax
    xor     %rdx, %rdx
    movq    $10, %rcx
    divq    %rcx

    movq    %rdx, %rsi
    movq    $timeprint, %rdi
    call    printf

.endm





main:
    pushq   %rbp
    movq    %rsp, %rbp

    INIT_GAME_AREA
    INIT_SNAKE
    DISPATCH_APPLE

    # prepare to init everything
    movl	$29233, %edi
    # init SDL
    call	SDL_Init

    #
    # draw stuff on canvas here
    #




    # shut down SDL
    call    SDL_Quit


    movq    $0, %rdi
    call    exit
