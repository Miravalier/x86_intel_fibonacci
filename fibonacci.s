.intel_syntax   noprefix

.section    .rodata
    .USAGE:     .string "usage: %s <int>\n"
    .LONG_FMT:  .string "%ld\n"

.section    .data
    .argc:      .long   0
    .argv:      .space  8,  0

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

    # Main program code
    cmp     edi,    2
    jne     error_out

    # Set return value
    mov     eax,    0

    # Restore base pointer and return
    pop     rbp
    ret

error_out:
    ARGV    0
    mov     rdi,    QWORD PTR stderr[rip]   # Err Stream
    mov     rsi,    OFFSET  .USAGE          # Usage Fmt
    mov     rdx,    rax                     # Argv 0
    xor     eax,    eax # Zero ax for printf
    call    fprintf     # Call printf
    mov	    edi,    1   # Ready exit parameter
    call	exit        # Exit the program
