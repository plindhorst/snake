.text


.globl main


main:
    pushq   %rbp
    movq    %rsp, %rbp

    # prepare to init everything
    movl	$29233, %edi
        
    # init call
    call	SDL_Init

    # shut down sdl
    call    SDL_Quit


    movq    $0, %rdi
    call    exit
