section .bss
    matA resq 256 ; reserve space for matrix A
    matB resq 256 ; reserve space for matrix B
    matC resq 256 ; reserve space for matrix C

    m resq 1 ; rows of A
    n resq 1 ; columns of A or rows of B
    q resq 1 ; columns of B

section .data
    dimensions: db "%lld %lld %lld", 0
    element: db "%lld", 0

extern scanf
extern printf

section .text
    global main

main:
    push rbp 
    mov rbp, rsp

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

    xor rax, rax  ; return 0
    leave
    ret

read_matrix:
    ; inputs: rax = matrix pointer, rbx = row, rcx = column
    xor r8, r8 ; set row iterator to zero
    
.row_loop:
    xor r9, r9 ; set column iterator to zero
.column_loop:
    ; Calculate correct matrix element address
    mov r10, r8
    imul r10, rcx  ; row * columns
    add r10, r9    ; + column
    
    ; Input element
    mov rdi, element
    lea rsi, [rax + r10 * 8]  ; Correct element address
    push rax
    push rbx
    push rcx
    push r8
    push r9
    call scanf

    pop r9
    pop r8
    pop rcx
    pop rbx
    pop rax

    inc r9
    cmp r9, rcx
    jl .column_loop

    inc r8
    cmp r8, rbx
    jl .row_loop

    ret
