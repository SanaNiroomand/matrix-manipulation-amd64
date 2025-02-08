%define SIZE 256

section .data
    ; reserve 64-bit doubles for matrices    
    matA: times SIZE dq 0
    matT: times SIZE dq 0
    matC: times SIZE dq 0
    matB: times SIZE dq 0

    m: dq 0 ; rows of A
    n: dq 0 ; columns of A and rows of B
    q: dq 0 ; columns of B

    dimensions: db "%lld %lld %lld", 0
    element_in: db "%lf", 0
    element_out: db "%.2lf ", 0
    newline: db 10, 0

extern scanf
extern printf

section .text
    global main

main:
    push rbp 
    mov rbp, rsp ; stack alignment

    ; reading input dimensions
    mov edi, dimensions
    lea rsi, [m]
    lea rdx, [n]
    lea rcx, [q]
    call scanf

    ; read matrix A
    lea rax, [matA]
    mov rbx, [m]
    mov rcx, [n]
    call read_matrix

    ; read matrix B (transpose)
    lea rax, [matT]
    mov rbx, [q]
    mov rcx, [n]
    call read_matrix

    call transpose

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

transpose:
    xor r8, r8
.row_loop:
    xor r9, r9
.column_loop:
    mov r10, r8
    imul r10, [n]
    add r10, r9

    mov r11, r9
    imul r11, [q]
    add r11, r8

    mov r12, [matT + r10 * 8]
    mov [matB + r11 * 8], r12 ; transpose logic

    inc r9
    cmp r9, [n]
    jl .column_loop

    inc r8
    cmp r8, [q]
    jl .row_loop

    ret

multiply_matrices:
    xor r8, r8 ; i = 0
.row_loop: 
    xor r9, r9 ; j = 0
.column_loop:
    pxor xmm0, xmm0 ; accumulator = 0

    xor r10, r10 ; k = 0

; implementing the dot product with vectors and parallelism in intersection loop
.intersection_loop:
    
    ; load 4 elements from A[i][k]
    mov r11, r8
    imul r11, [n] ; row * columns
    add r11, r10 ; + column
    movupd xmm1, [matA + r11 * 8] ; A[i][k:k+4]

    ; load 4 elements from B[k][j]
    mov r11, r9
    imul r11, [n] ; row * columns
    add r11, r10 ; + column
    movupd xmm2, [matB + r11 * 8] ; B[k:k+4][j]

    mulpd xmm1, xmm2
    addpd xmm0, xmm1

    add r10, 2 ; k += 2 processing two doubles at a time with SSE registers
    cmp r10, [n]
    jl .intersection_loop

    mov r11, r8
    imul r11, [q] ; row * columns
    add r11, r9 ; + column
    movsd [matC + r11 * 8], xmm0 ; store the result in C[i][j]

    inc r9 ; j++
    cmp r9, [q]
    jl .column_loop

    inc r8 ; i++
    cmp r8, [m]
    jl .row_loop

    ret

print_matrix:
    xor r8, r8 ; i = 0
.row_loop:
    xor r9, r9 ; j = 0
.column_loop:
    mov rax, r8
    mul qword [q] ; row * columns
    add rax, r9 ; + column
    shl rax, 3 ; 8 bytes for each number

    push r8 ; push needed registers
    push r9

    mov rdi, element_out
    mov rsi, [matC + rax]
    xor rax, rax
    call printf ; print C[i][j]

    pop r9
    pop r8

    inc r9
    cmp r9, [q]
    jl .column_loop

    push r8
    push r9

    mov rdi, newline
    xor rax, rax
    call printf ; print newline

    pop r9
    pop r8

    inc r8
    cmp r8, [m]
    jl .row_loop

    ret