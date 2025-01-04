section .bss
    matA resq 256 ; reserve space for matrix A
    matB resq 256 ; reserve space for matrix B
    matC resq 256 ; reserve space for matrix C

    m resq 1 ; rows of A
    n resq 1 ; columns of A or rows of B
    q resq 1 ; columns of B

section .data
    dimensions: db "%lld %lld %lld", 0
    element_in: db "%lld", 0
    element_out: db "%lld ", 0
    newline: db 10, 0

extern scanf
extern printf

section .text
    global main

main:
    push rbp 
    mov rbp, rsp ; stack alignment

    ; reading input dimensions
    mov rdi, dimensions
    lea rsi, [m]
    lea rdx, [n]
    lea rcx, [q]
    call scanf

    ; read matrix A
    lea rax, [matA]
    mov rbx, [m]
    mov rcx, [n]
    call read_matrix

    ; read matrix B
    lea rax, [matB]
    mov rbx, [n]
    mov rcx, [q]
    call read_matrix

    call multiply_matrices

    call print_matrix

    xor rax, rax  ; return 0
    leave ; stack alignment
    ret

read_matrix:
    ; inputs: rax = matrix pointer, rbx = row, rcx = column
    xor r8, r8 ; set row iterator to zero
    
.row_loop:
    xor r9, r9 ; set column iterator to zero
.column_loop:
    mov r10, r8
    imul r10, rcx  ; row * columns
    add r10, r9    ; + column
    
    ; input element
    mov rdi, element_in
    lea rsi, [rax + r10 * 8]
    push rax ; push needed register before being changed by call
    push rbx
    push rcx
    push r8
    push r9
    call scanf

    pop r9 ; pop the registers
    pop r8
    pop rcx
    pop rbx
    pop rax

    inc r9 ; increase column iterator
    cmp r9, rcx
    jl .column_loop

    inc r8 ; increase row iterator
    cmp r8, rbx
    jl .row_loop

    ret

multiply_matrices:
    xor r8, r8
.row_loop:
    xor r9, r9
.column_loop:
    xor r10, r10
.intersection_loop:
    mov r11, r8
    imul r11, [n]
    add r11, r10

    mov r12, r10
    imul r12, [q]
    add r12, r9

    mov r13, r8
    imul r13, [q]
    add r13, r9

    mov r14, [matA + r11 * 8]
    imul r14, [matB + r12 * 8]
    add [matC + r13 * 8], r14

    inc r10
    cmp r10, [n]
    jl .intersection_loop

    inc r9
    cmp r9, [q]
    jl .column_loop

    inc r8
    cmp r8, [m]
    jl .row_loop

    ret

print_matrix:
    xor r8, r8
.row_loop:
    xor r9, r9
.column_loop:
    mov rax, r8
    mul qword [q]
    add rax, r9
    shl rax, 3

    push r8
    push r9

    mov rdi, element_out
    mov rsi, [matC + rax]
    xor rax, rax
    call printf

    pop r9
    pop r8

    inc r9
    cmp r9, [q]
    jl .column_loop

    push r8
    push r9

    mov rdi, newline
    xor rax, rax
    call printf

    pop r9
    pop r8

    inc r8
    cmp r8, [m]
    jl .row_loop

    ret

; defines and macros
