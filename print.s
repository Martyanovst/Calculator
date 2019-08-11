 .macro print str, strlen
    mov $1, %rax
    mov \str, %rsi
    mov $1, %rdi
    mov \strlen, %rdx
    syscall
.endm
