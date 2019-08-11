.include "readline.s"
.include "print.s"
.globl _start
.text
_start:
    readline $input # Number of bytes read in rcx
    mov $input, %rsi
    mov $postfixnotation, %rdi
    call сvtpstfixnot
    sub $postfixnotation, %rcx 
    push %rcx
    #print $postfixnotation, %rcx
    pop %rcx
    mov $postfixnotation, %rsi
    mov $result, %rdi
    call calculate
    movb $10, 9(%rdi)
    print %rdi, $10
    mov $60, %rax
    syscall 
.bss
    .lcomm input, 100
    .lcomm postfixnotation, 200
    .lcomm result, 8
.data
