.include "print.s"

.macro pow base, power
    mov \power, %r13
    dec %r13
    mov $1, %rax
    test %r13, %r13
    jz e\base
    mov \base, %r14
mult\base:
    mul %r14
    dec %r13
    test %r13, %r13
    jnz mult\base
e\base:
.endm
.macro match case, mark, value
    cmpb \case, \value
    je \mark
.endm
.globl calculate
#rsi - source expression in postfix notation
#rdi - result string
#r8 - stack counter
#r11- source counter
.text
calculate:
    mov %rcx, %r11 
    xor %r8, %r8
nextByte:
    test %r11, %r11
    jz finish
    cmpb $32, (%rsi)
    jg notspace
    inc %rsi
    dec %r11
    jmp nextByte
notspace:
    cmpb $48, (%rsi)
    jl notOperand
    cmpb $57, (%rsi)
    jg notOperand
    jmp pushOperand
notOperand:
    match $43, add, (%rsi)
    match $45, sub, (%rsi)
    match $42, mul, (%rsi)
    match $94, pow, (%rsi)
    match $37, mod, (%rsi)
    match $47, div, (%rsi)
    match $35, abs, (%rsi)
    match $33, sgn, (%rsi)
    match $126, neg, (%rsi)
    match $120, xor, (%rsi)
    match $111, or, (%rsi)
    match $100, and, (%rsi)
    jmp fail
add:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    add %rbx, %rax
    jmp success
sub:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    sub %rbx, %rax
    jmp success
mul:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    imul %rbx
    jmp success
pow:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    test %rbx, %rbx
    mov %rax, %rcx
    js fail
    test %rbx, %rbx
    jnz 1f
    mov $1, %rax
    jmp success
1:
    dec  %rbx
    test %rbx, %rbx
    jz 1f
    imul %rcx
    jmp 1b
1:
    jmp success
mod:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    xor %rdx, %rdx
    idiv %rbx
    mov %rdx, %rax
    jmp success
div:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    test %rbx, %rbx
    jz divisionByZero
    xor %rdx, %rdx
    idiv %rbx
    jmp success
abs:
    test %r8, %r8
    jz fail 
    pop %rax
    dec %r8
    test %rax, %rax
    jns 1f
    neg %rax
1:
    jmp success
sgn:
    test %r8, %r8
    jz fail 
    pop %rax
    dec %r8
    test %rax, %rax
    jnz 1f
    jmp success
1:
    test %rax, %rax
    js 1f
    mov $1, %rax 
    jmp success
1:  
    mov $-1, %rax
    jmp success
neg:
    test %r8, %r8
    jz fail 
    pop %rax
    dec %r8
    neg %rax
    jmp success
xor:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    xor %rbx, %rax
    jmp success
or:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    or %rbx, %rax
    jmp success
and:
    cmp $2, %r8
    jl fail 
    pop %rbx
    pop %rax
    sub $2, %r8
    and %rbx, %rax
    jmp success
success:
    push %rax
    inc %r8
    inc %rsi
    dec %r11
    jmp nextByte
pushOperand:
    cmpb $120, 1(%rsi)
    jne decimal
    cmpb $48, (%rsi)
    jne decimal
    jmp Hex
decimal:
    xor %rcx, %rcx
next:
    inc %rcx
    inc %rsi
    cmpb $48, (%rsi)
    jl end
    cmpb $57, (%rsi)
    jg end
    jmp next
end:
    sub %rcx, %rsi
    xor %rbx, %rbx
1:  
    xor %r12, %r12
    movb (%rsi), %r12b
    sub $48, %r12
    pow $10, %rcx
    mul %r12
    add %rax, %rbx
    inc %rsi
    dec %r11
    dec %rcx
    jnz 1b
    push %rbx
    inc %r8
    jmp nextByte
Hex:
    xor %rcx, %rcx
    inc %rsi
    dec %r11
Hnext:
    inc %rcx
    inc %rsi
    dec %r11
    cmpb $48, (%rsi)
    jl Hend
    cmpb $57, (%rsi)
    jg MayBeAF
    jmp Hnext
Hend:
    dec %rcx
    sub %rcx, %rsi
    xor %rbx, %rbx
1:    
    xor %r12, %r12
    movb (%rsi), %r12b
    sub $48, %r12
    cmp $10, %r12
    jng 2f
    sub $7, %r12
2:
    pow $16, %rcx
    mul %r12
    add %rax, %rbx
    inc %rsi
    dec %rcx
    jnz 1b
    push %rbx
    inc %r8
    jmp nextByte
MayBeAF:
    cmpb $65, (%rsi)
    jl Hend
    cmpb $70, (%rsi)
    jg Hend
    jmp Hnext

fail:
    print $error, $errorlen
    mov $60, %rax
    syscall
finish:
    pop %r9
    dec %r8
    test %r8, %r8
    jnz fail
    xor %r10, %r10
    test %r9, %r9
    jz zero
    test %r9, %r9
    js negative
    mov %r9, %rax
3:
    mov $10, %rbx
    add $8, %rdi
1:
    xor %rdx, %rdx
    idiv %rbx
    test %rax, %rax
    jnz 2f
    test %rdx, %rdx
    jnz 2f
q:
    test %r10b, %r10b
    jz 4f
    dec %rdi
    movb $45, (%rdi)
4:
    ret
2:
    add $48, %dl
    movb %dl, (%rdi)
    dec %rdi
    jmp 1b
    
negative:
    neg %rax
    movb $1, %r10b
    inc %rdi
    jmp 3b
zero:
    movb $48, (%rdi)
    ret
divisionByZero:
    print $dbz, $dbzLen
    mov $60, %rax
    syscall
.data
error: .ascii "INVALID EXPRESSION\n"
errorlen = . - error
dbz: .ascii "Division by zero\n"
dbzLen = . - dbz
