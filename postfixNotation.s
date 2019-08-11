# 2+( 3+ < 1-5>)
#2+ 0x12432F -(0x0A * 12%(24*0xAABBCC)) = 2+ 1196847 - (5/11189196) = 1196849 
# 12 /3 - 2*(<4-2>)
.include "print.s"
.macro cell state, char, dest 
    .ascii "\char"
    .byte \state
    .word 0xDEAD, 0x00, 0x00
    .byte \dest, 0
    .word 0xFFFF, 0xFFFF, 0xFFFF
.endm
.macro priora value, res, operator, result, to
    cmpb \value, \operator 
    jne 1f
    mov \res, \result
    jmp \to
1:
.endm
.macro getPriority operator, result, idx
    priora $40, $-1, \operator, \result, finish\idx # (
    priora $41, $0, \operator, \result, finish\idx # )
    priora $60, $-1, \operator, \result, finish\idx # <
    priora $62, $0, \operator, \result, finish\idx # >
    priora $91, $-1, \operator, \result, finish\idx # [
    priora $92, $0, \operator, \result, finish\idx # ]
    priora $43, $1, \operator, \result, finish\idx    # +
    priora $45, $2,  \operator, \result, finish\idx   # -
    priora $111, $3, \operator, \result, finish\idx # or
    priora $120, $3, \operator, \result, finish\idx # xor
    priora $100, $5, \operator, \result, finish\idx  # and
    priora $42, $6, \operator, \result, finish\idx       # *
    priora $47, $6, \operator, \result, finish\idx       # /
    priora $37, $3, \operator, \result, finish\idx       # %
    priora $94, $8, \operator, \result, finish\idx       # ^
    priora $126, $10, \operator, \result, finish\idx     # ~
    jmp fail
finish\idx:
.endm
.globl сvtpstfixnot
.text

.macro writeToken
w:
    cmpb $8, %al
    jne 1f
    cmpb $120, %r8b
    jne 1f
    movb %r8b, (%r9)
    jmp success
1:
    cmpb $3, %bl
    jng 1f
    cmpb $7, %bl
    jng end
1:
    cmp $120, %r8b 
    je end
    cmp $97, %r8b
    je end
    cmp $111, %r8b
    je end
    cmp $10, %r8b #\n
    je popup
    cmpb $48, %r8b #0
    jl notdecimal
    cmpb $57, %r8b #9
    jg notdecimalButMaybeHex
    movb %r8b, (%r9)
    jmp success
notdecimalButMaybeHex:
    cmpb $65, %r8b
    jl notdecimal
    cmpb $70, %r8b
    jg notdecimal
    movb %r8b, (%r9)
    jmp success
notdecimal:
    cmpb $32, %r8b # ' '
    jne notspace
    cmpb $1, %al
    je 1f
    jmp end
  1:  
    movb %r8b, (%r9)
    jmp success
notspace:
    cmpb $40, %r8b # (
    je bracket
    cmpb $60, %r8b # < 
    je bracket
    cmpb $91, %r8b # | 
    je bracket
    cmpb $41, %r8b # )
    je closeBracket
    cmpb $62, %r8b # >
    je closeSign
    cmpb $93, %r8b # >
    je closeModule
    jmp operator
bracket:
    push %r8
    inc %r14
    jmp end
module:
    test %r12, %r12
    jnz on
    movb %r8b, (%r9)
on: #|
    pop %r8
    dec %r14
    movb %r8b, (%r9)
    inc %r9
    cmpb $124, %r8b
    jne on
    jmp success
closeBracket: # )
    test %r14, %r14
    jz fail
    pop %r8
    dec %r14
    cmpb $60, %r8b
    je fail
    cmpb $41, %r8b
    je fail
    cmpb $91, %r8b
    je fail
    cmpb $40, %r8b
    je success
    movb %r8b, (%r9)
    inc %r9
    jmp closeBracket
closeSign: #>
    test %r14, %r14
    jz fail
    pop %r8
    dec %r14
    cmpb $40, %r8b
    je fail
    cmpb $91, %r8b
    je fail
    cmpb $62, %r8b
    je fail
    cmpb $60, %r8b
    je 1f
    movb %r8b, (%r9)
    inc %r9
    jmp closeSign
1:
    movb $33, (%r9)
    jmp success
closeModule: # )
    test %r14, %r14
    jz fail
    pop %r8
    dec %r14
    cmpb $60, %r8b
    je fail
    cmpb $40, %r8b
    je fail
    cmpb $93, %r8b
    je fail
    cmpb $91, %r8b
    je 1f
    movb %r8b, (%r9)
    inc %r9
    jmp closeModule
1:
    movb $35, (%r9) 
    jmp success
operator:
    cmpb $114, %r8b 
    jne 2f
    cmpb $6, %al
    jne 1f
    movb $120, %r8b
    jmp 2f
1:
    movb $111, %r8b
2:
    test %al, %al
    jnz 1f
    cmpb $43, %r8b
    jne 5f
    jmp end
5:
    cmpb $45, %r8b
    jne 1f
    movb $126, %r8b
    push %r8
    inc %r14
    jmp end
1:    
    movb $32, (%r9)
    inc %r9
    test %r14, %r14
    jnz stackIsNotEmpty
    push %r8
    inc %r14
    jmp end
stackIsNotEmpty:
    getPriority %r8b, %r11, 1
    movb (%rsp), %bl
    getPriority %bl, %rax, 2
    cmpb %al, %r11b
    jg greater
    pop %rax
    dec %r14
    movb %al, (%r9)
    inc %r9
greater:
    push %r8
    inc  %r14
    jmp end
popup:
    test %r14, %r14
    jnz 1f
    mov %r9, %rcx
    ret
1:
    pop %rax
    movb %al, (%r9)
    dec %r14
    inc %r9
    jmp popup
success:
    inc %r9
end:
.endm

# rsi - source / rdi - destination rcx - source length
сvtpstfixnot:
    mov $0, %dl         #state
    mov %rdi, %r9 # r9- destination
    mov %rcx,%r10 
    xor %r12, %r12
    xor %r14, %r14 # r14 -stack counter
lp:
    cmp $0, %r10
    je ex

    movb %dl, %r15b # r15b - current state
    mov $0xDEADDEAD, %eax
    mov %dl, %ah
    movb (%rsi), %al
    movb (%rsi), %r8b # r8b - current char

    mov $ls, %rcx
    shr $3, %rcx
    mov $ss, %rdi
    repnz scasq #rdi -> offset-part

    cmp $after, %rdi
    je fail
    movb (%rdi), %dl
    movb %r15b, %al
    movb %dl, %bl
    writeToken
    inc %rsi
    dec %r10

    jmp lp
ex:
    ret
fail:
    print $error, $errorlen
    mov $60, %rax
    syscall

.data
    ss: .word 0, 0, 0, 0, 0, 0, 0, 0
    s0: 
     cell 0, "+", 0
     cell 0, "-", 0
     cell 0, "(", 0
     cell 0, "<", 0
     cell 0, "[", 0
     cell 0, " ", 0
     cell 0, "1", 1
     cell 0, "2", 1
     cell 0, "3", 1
     cell 0, "4", 1
     cell 0, "5", 1
     cell 0, "6", 1
     cell 0, "7", 1
     cell 0, "8", 1
     cell 0, "9", 1
     cell 0, "0", 8
     cell 0, "\n",3
    s1:
     cell 1, "0", 1
     cell 1, "1", 1
     cell 1, "2", 1
     cell 1, "3", 1
     cell 1, "4", 1
     cell 1, "5", 1
     cell 1, "6", 1
     cell 1, "7", 1
     cell 1, "8", 1
     cell 1, "9", 1
     cell 1, " ", 2
     cell 1, "+", 0
     cell 1, "-", 0
     cell 1, "*", 0
     cell 1, "^", 0
     cell 1, "/", 0
     cell 1, "%", 0
     cell 1, ")", 2
     cell 1, ">", 2
     cell 1, "]", 2
     cell 1, "\n", 3
     cell 1, "x", 3
     cell 1, "o", 4
     cell 1, "a", 5
    s2:
     cell 2, " ", 2
     cell 2, "+", 0
     cell 2, "-", 0
     cell 2, "*", 0
     cell 2, "^", 0
     cell 2, "/", 0
     cell 2, "%", 0
     cell 2, ")", 2
     cell 2, ">", 2
     cell 2, "]", 2
     cell 2, "\n", 3
     cell 2, "x", 3
     cell 2, "o", 4
     cell 2, "a", 5
s3:
     cell 3, "o", 6
s4:
     cell 4, "r", 0  
s5:
     cell 5, "n", 7
s6:
     cell 6, "r", 0
s7:
     cell 7, "d", 0
s8:
     cell 8, "x", 9
     cell 8, " ", 2
     cell 8, "+", 0
     cell 8, "-", 0
     cell 8, "*", 0
     cell 8, "^", 0
     cell 8, "/", 0
     cell 8, "%", 0
     cell 8, ")", 2
     cell 8, ">", 2
     cell 8, "]", 2
     cell 8, "\n", 3
     cell 8, "x", 3
     cell 8, "o", 4
     cell 8, "a", 5 

s9: 
     cell 9, "0", 9
     cell 9, "1", 9
     cell 9, "2", 9
     cell 9, "3", 9
     cell 9, "4", 9
     cell 9, "5", 9
     cell 9, "6", 9
     cell 9, "7", 9
     cell 9, "8", 9
     cell 9, "9", 9
     cell 9, "A", 9
     cell 9, "B", 9
     cell 9, "C", 9
     cell 9, "D", 9
     cell 9, "E", 9
     cell 9, "F", 9
     cell 9, " ", 2
     cell 9, "+", 0
     cell 9, "-", 0
     cell 9, "*", 0
     cell 9, "^", 0
     cell 9, "/", 0
     cell 9, "%", 0
     cell 9, ")", 2
     cell 9, ">", 2
     cell 9, "]", 2
     cell 9, "\n", 3
     cell 9, "x", 3
     cell 9, "o", 4
     cell 9, "a", 5
    ls = . - ss
    after: .word 0, 0, 0, 0
error: .ascii "INVALID EXPRESSION\n"
errorlen = . - error
