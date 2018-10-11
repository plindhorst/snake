section .data
# starting position: third row, third column, three-block snake
starthead: .byte 765
startlength: .byte 3

section .bss
# screen:
gamearea: .skip 4032
# maximum length of snake is the same as game area, queue needs +1:
snakequeue: .skip 365


section .text

.globl main

main:
    pushq   %rbp
    movq    %rsp, %rbp

    initgamearea
    initsnake

    # prepare to init everything
    movl	$29233, %edi
    # init call
    call	SDL_Init

    #
    # draw stuff on canvas here
    #




    # shut down sdl
    call    SDL_Quit


    movq    $0, %rdi
    call    exit


.macro initgamearea

.endm

.macro initsnake

.endm
