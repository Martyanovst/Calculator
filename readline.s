.macro readline buff
    mov \buff, %rsi     # buffer = address to store the bytes read
    push %rsi
    readNextByte:
    xor %rdi, %rdi      # file descriptor = stdin = 0
    mov $1, %rdx        # number of bytes to read
    xor %rax, %rax      # SYSCALL number for reading from STDIN
    syscall
    mov (%rsi), %bl
    inc %rsi
    cmp $10, %bl
    jne readNextByte
    pop %r11
    lea (%rsi), %rcx
    sub %r11, %rcx
.endm    
