.intel_syntax   noprefix

.section    .rodata
    .USAGE:     .string "usage: %s <0 .. n .. 100>\n"
    .LONG_FMT:  .string "%ld"
    .HEX_FMT:   .string "%lx"

.section    .data
    .argc:      .long   0
    .argv:      .space  8,  0
    .index:     .space  8,  0
    .limit:     .space  8,  0
    .previous:  .space  32, 0
    .current:   .space  32, 0
    .tmp:       .space  32, 0
    .end_ptr:   .space  8,  0

.macro  ARGV    INDEX=1
mov     rax,    .argv           # Get ARGV address in memory
mov     rdx,    \INDEX          # Get INDEX into a register
shl     rdx,    3               # Multiply INDEX by 8
add     rax,    rdx             # Add OFFSET to ARGV
mov     rax,    QWORD PTR [rax] # Move ARGV[INDEX] into rdi
.endm

.section    .text
.globl  main
.type   main, @function
main:
    # Save base pointer
    push    rbp

    # Save out argc and argv to ram
    mov     [.argc],    edi
    mov     [.argv],    rsi

    # Set current to 1 and previous to 0
    mov     QWORD PTR [.current],   1
    mov     QWORD PTR [.previous],  0

    # Validate argc == 2
    cmp     edi,    2   # Compare argc to 2
    jne     .L_error_out   # Error with usage if !=
    ARGV    1

    # Get limit and validate it is an integer
    mov     rdi,    rax             # Str
    mov     rsi,    OFFSET .end_ptr # End
    mov     rdx,    0               # Base
    call    strtol
    mov     [.limit],   rax         # Move return of strtol into limit
    lea     rsi,        .end_ptr    # Get the endptr again, rsi is not preserved
    mov     rsi,        [rsi]       # Get char* value in **rsi
    mov     al,         [rsi]       # Get the char in *rsi
    cmp     al,         0           # Check character against NULL
    jne     .L_error_out               # Exit if character != NULL

    # Validate 0 <= limit <= 100
    cmp     QWORD PTR [.limit], 0   # Compare limit against 0
    jl      .L_error_out               # If <, error out
    cmp     QWORD PTR [.limit], 100 # Compare limit against 100
    jg      .L_error_out               # If >, error out

    # Check for full cases
    cmp     QWORD PTR [.limit], 1
    jg      .L_main_regular_case
    # Default to base case
    jmp     .L_main_base_case
    
.L_main_base_case:
    mov     rax, [.limit]
    mov     [.current], rax
    call    big_print
    jmp     .L_main_end

.L_main_regular_case:
    jmp     .L_main_end

.L_main_end:
    # Set return value
    mov     eax,    0

    # Restore base pointer and return
    pop     rbp
    ret


.L_error_out:
    ARGV    0
    mov     rdi,    QWORD PTR stderr[rip]   # Err Stream
    mov     rsi,    OFFSET  .USAGE          # Usage Fmt
    mov     rdx,    rax                     # Argv 0
    xor     eax,    eax # Zero ax for printf
    call    fprintf     # Call printf
    mov	    edi,    1   # Ready exit parameter
    call	exit        # Exit the program

.type   big_print, @function
big_print:
    mov     rdi,    OFFSET .HEX_FMT
    mov     rsi,    [.current]
    xor     eax,    eax
    call    printf
    mov     edi,    '\n'
    call    putchar
    ret

.type   big_add, @function
big_add:
    ret

.type   big_cpy, @function
big_cpy:
    ret
