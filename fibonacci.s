.intel_syntax   noprefix

.section    .rodata
    .USAGE:     .string "usage: %s <0 .. n .. 100>\n"
    .LONG_FMT:  .string "%ld"
    .HEX_FMT:   .string "%016lX"
    .OCT_FMT:   .string "%021lo"

.section    .data
    .out_buff:  .space  64, 0
    .previous:  .space  16, 0
    .current:
        .byte   1
        .space  15, 0
    .tmp:       .space  16, 0
    .argv:      .space  8,  0
    .index:
        .byte   1
        .space  7,  0
    .limit:     .space  8,  0
    .end_ptr:   .space  8,  0
    .argc:      .long   0
    .fmt:       .byte   'x'

.macro  ARGV    INDEX=1
mov     rdx,    \INDEX          # Get INDEX into a register
mov     rax,    .argv           # Get ARGV address in memory
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

    # Make sure at least 2 args
    cmp     edi,    2       # Compare argc to 2
    jl     .L_error_out     # Error with usage if <

    # Get each argv from 1 on
    mov     rcx,    1
    .L_param_loop:
    push    rcx
    ARGV    rcx                     # Get next arg into rax
    pop     rcx
    cmp     BYTE PTR [rax],     '-' # Check for -
    jne     .L_param_int            # Jump if a0 != - to process limit
    cmp     BYTE PTR [rax+1],   'o' # Check for o
    jne     .L_param_int            # Jump if a1 != o to process limit
    jmp     .L_param_oflag
    .L_param_inc_loop:
    inc     rcx             # Increment counter
    cmp     ecx,    [.argc]
    jl      .L_param_loop
    jmp     .L_param_loop_end
    .L_param_oflag:
    # Process -o flag
    mov     BYTE PTR [.fmt],    'o'
    jmp     .L_param_inc_loop
    .L_param_int:
    # Get limit and validate it is an integer
    mov     rdi,    rax             # Str
    mov     rsi,    OFFSET .end_ptr # End
    mov     rdx,    0               # Base
    push    rcx
    call    strtol
    pop     rcx
    mov     [.limit],   rax         # Move return of strtol into limit
    lea     rsi,        .end_ptr    # Get the endptr again, rsi is not preserved
    mov     rsi,        [rsi]       # Get char* value in **rsi
    xor     eax,        eax         # Zero RAX
    mov     al,         [rsi]       # Get the char in *rsi
    cmp     al,         0           # Check character against NULL
    jne     .L_error_out            # Exit if character != NULL
    jmp     .L_param_inc_loop

    .L_param_loop_end:
    # Validate 0 <= limit <= 100
    cmp     QWORD PTR [.limit], 0   # Compare limit against 0
    jl      .L_error_out            # If <, error out
    cmp     QWORD PTR [.limit], 100 # Compare limit against 100
    jg      .L_error_out            # If >, error out

    # Check for full cases
    cmp     QWORD PTR [.limit], 1
    jg      .L_main_regular_case
    # Default to base case
    jmp     .L_main_base_case
    
.L_main_base_case:
    # Print 0x prefix
    mov     edi,    '0'
    call    putchar
    xor     eax,    eax             # Zero eax
    mov     al,     BYTE PTR [.fmt] # Get format char
    mov     edi,    eax             # Provide to putchar
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
    # Move to next fibonacci number
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

.type   big_print,  @function
big_print:
    cmp     BYTE PTR [.fmt], 'x'  # Format == x
    je      .L_big_print_hex    # If
    jmp     .L_big_print_oct    # Else

.L_big_print_oct:
    # Move highest bit of lower value into lowest bit
    # of higher value ... 
    # 000 011 100 011  =  000 111 000 011
    shl     QWORD PTR [.current+8], 1
    shl     QWORD PTR [.current],   1
    adc     QWORD PTR [.current+8], 0
    shr     QWORD PTR [.current],   1

    # Build an output buffer
    mov     rdi,    OFFSET .out_buff    # char* str
    mov     rsi,    OFFSET [.OCT_FMT]   # char* format
    mov     rdx,    [.current+8]        # most significant bytes
    xor     eax,    eax
    call    sprintf

    mov     rdi,    OFFSET .out_buff+21 # char* str
    mov     rsi,    OFFSET [.OCT_FMT]   # char* format
    mov     rdx,    [.current]          # least significant bytes
    xor     eax,    eax
    call    sprintf

    # Append 0o
    mov     edi,    '0'                 # Move '0' into first param of putchar
    call    putchar
    mov     edi,    'o'                 # Provide param to putchar
    call    putchar                     # Call putchar

    # Trim leading zeroes from buffer
    mov     rax,    OFFSET .out_buff    # Move buff ptr into rax
    jmp     .L_big_print_loop

.L_big_print_hex:
    # Build an output buffer
    mov     rdi,    OFFSET .out_buff    # char* str
    mov     rsi,    OFFSET [.HEX_FMT]   # char* format
    mov     rdx,    [.current+8]        # most significant bytes
    xor     eax,    eax
    call    sprintf

    mov     rdi,    OFFSET .out_buff+16 # char* str
    mov     rsi,    OFFSET [.HEX_FMT]   # char* format
    mov     rdx,    [.current]          # least significant bytes
    xor     eax,    eax
    call    sprintf

    # Append 0x
    mov     edi,    '0'                 # Move '0' into first param of putchar
    call    putchar
    mov     edi,     'x'                # Get format char
    call    putchar                     # Call putchar

    # Trim leading zeroes from buffer
    mov     rax,    OFFSET .out_buff    # Move buff ptr into rax
    jmp     .L_big_print_loop

.L_big_print_loop:
    add     rax,            1       # Move to next char
    cmp     BYTE PTR [rax], '0'     # Compare current value to '0'
    jne     .L_big_print_loop_end   # If != '0', we're done
    jmp     .L_big_print_loop       # Else increment again

.L_big_print_loop_end:
    # Print remaining hex number
    mov     rdi,            rax     # Move ptr into first param
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
    mov     rax,            [.previous]     # a = previous[0]
    add     [.current],     rax             # current[0] += a
    mov     rax,            [.previous+8]   # a = previous[1]
    adc     [.current+8],   rax             # current[1] += a

    # Move tmp into previous
    mov     rax,            [.tmp]      # a = current[0]
    mov     [.previous],    rax         # tmp[0] = a
    mov     rax,            [.tmp+8]    # a = current[1]
    mov     [.previous+8],  rax         # tmp[1] = a
    
    ret
