.intel_syntax   noprefix

.section    .rodata
    .USAGE:     .string "usage: %s <0 .. n .. 100>\n"
    .LONG_FMT:  .string "%ld"
    .HEX_FMT:   .string "%08lX"

.section    .data
    .argc:      .long   0
    .argv:      .space  8,  0
    .index:     .space  8,  0
    .limit:     .space  8,  0
    .previous:  .space  16, 0
    .current:   .space  16, 0
    .tmp:       .space  16, 0
    .end_ptr:   .space  8,  0
    .hex_buff:  .space  64, 0

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

    # Set current, index, and previous
    mov     QWORD PTR [.current],   1
    mov     QWORD PTR [.previous],  0
    mov     QWORD PTR [.index],     1

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
    # Print 0x prefix
    mov     edi,    '0'
    call    putchar
    mov     edi,    'x'
    call    putchar

    # Print number
    mov     rdi,    [.limit]
    add     rdi,    '0'
    call    putchar

    # Print newline
    mov     edi,    '\n'
    call    putchar
    jmp     .L_main_end

.L_main_regular_case:
    call    big_add

    # Increment index
    inc     QWORD PTR [.index]

    # Check for loop end or restart
    mov     rax,        [.limit]
    cmp     [.index],   rax
    je      .L_main_loop_end
    jmp     .L_main_regular_case

.L_main_loop_end:
    # Print result
    call    big_print
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
    # Build an output buffer
    mov     rdi,    OFFSET .hex_buff    # char* str
    mov     rsi,    OFFSET .HEX_FMT     # char* format
    mov     rdx,    [.current+8]        # most significant bytes
    xor     eax,    eax
    call    sprintf

    mov     rdi,    OFFSET .hex_buff+8  # char* str
    mov     rsi,    OFFSET .HEX_FMT     # char* format
    mov     rdx,    [.current]          # least significant bytes
    xor     eax,    eax
    call    sprintf

    # Append 0x
    mov     edi,    '0' # Move '0' into first param of putchar
    call    putchar     # Call putchar
    mov     edi,    'x' # Move '0' into first param of putchar
    call    putchar     # Call putchar

    # Print hex number
    mov     rax, OFFSET .hex_buff   # Set ptr to buffer
    mov     rdi,    rax             # Move ptr into first param of puts
    call    puts                    # Call puts

    ret


.type   big_add, @function
big_add:
    # Move current into tmp
    mov     rax,        [.current]      # a = current[0]
    mov     [.tmp],     rax             # tmp[0] = a
    mov     rax,        [.current+8]    # a = current[1]
    mov     [.tmp+8],   rax             # tmp[1] = a

    # Add previous to current
    mov     rax,            [.tmp]      # a = tmp[0]
    add     [.current],     rax         # current[0] += a
    mov     rax,            [.tmp+8]    # a = tmp[1]
    adc     [.current+8],   rax         # current[1] += a

    # Move tmp into previous
    mov     rax,        [.tmp]      # a = current[0]
    mov     [.previous],     rax    # tmp[0] = a
    mov     rax,        [.tmp+8]    # a = current[1]
    mov     [.previous+8],   rax    # tmp[1] = a
    
    ret


.type   big_cpy, @function
big_cpy:
    ret
