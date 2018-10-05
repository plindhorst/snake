.text


.globl main


main:
    pushq   %rbp
    movq    %rsp, %rbp          # stack frame

    movl	$29233, %edi        # init everything
	call	SDL_Init            # init call
    call    SDL_Quit            # shut down sdl


    movq    $0, %rdi
    call    exit
