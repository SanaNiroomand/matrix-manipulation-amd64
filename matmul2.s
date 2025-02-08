%define SIZE 256

section .data
    ; reserve 32-bit floats for matrices    
    matA: times SIZE dd 0
    matT: times SIZE dd 0
    matC: times SIZE dd 0
    matB: times SIZE dd 0

    n: dd 0 ; rows of A
    m: dd 0 ; columns of A and rows of B
    q: dd 0 ; columns of B

    dimensions: db "%d %d %d", 0
    element_in: db "%f", 0
    element_out: db "%.2f ", 0
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
    lea esi, [m]
    lea edx, [n]
    lea ecx, [q]
    call scanf

    ; read matrix A
    lea eax, [matA]
    mov ebx, [m]
    mov ecx, [n]
    call read_matrix

    ; read matrix B (transpose)
    lea eax, [matT]
    mov ebx, [n]
    mov ecx, [q]
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
    lea rsi, [rax + r10 * 4]
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
    imul r10, r9
    add r10, r9

    mov r11, r9
    imul r11, r8
    add r11, r8

    mov r12, [matT + r10 * 8]
    mov [matB + r11 * 8], r12 ; transpose logic

    inc r9
    cmp r9, [n]
    jl .column_loop

    inc r8
    cmp r8, [m]
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
    
    ; load 8 elements from A[i][k] (unroll by 4)
    mov r11, r8
    imul r11, [n] ; row * columns
    add r11, r10 ; + column
    movss xmm1, [matA + r11 * 4] ; A[i][k:k+7]

    ; load 8 elements from B[k][j] (unroll by 4)
    mov r11, r9
    imul r11, [n] ; row * columns
    add r11, r10 ; + column
    movss xmm2, [matB + r11 * 4] ; B[k:k+7][j]

    mulss xmm1, xmm2
    addss xmm0, xmm1

    add r10, 8 ; k += 8
    cmp r10, [n]
    jl .intersection_loop

    mov r11, r8
    imul r11, [q] ; row * columns
    add r11, r9 ; + column
    movss [matC + r11 * 4], xmm0 ; store the result in C[i][j]

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
    shl rax, 2 ; 4 bytes for each number

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