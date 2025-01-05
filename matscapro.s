section .bss
    matX resq 256 ; reserve space for matrix X
    matY resq 256 ; reserve space for matrix Y
    matZ resq 256 ; reserve space for matrix Z = XY
    matXT resq 256 ; reserve space for matrix X transpose

    m resq 1 ; rows of X or columns of Y
    n resq 1 ; columns of X or rows of Y

section .data
    dimensions: db "%lld %lld", 0
    element_in: db "%lld", 0
    output: db "%lld", 0

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
    call scanf

    ; read matrix X
    lea rax, [matX]
    mov rbx, [m]
    mov rcx, [n]
    call read_matrix

    ; read matrix Y
    lea rax, [matY]
    mov rbx, [m]
    mov rcx, [n]
    call read_matrix

    call transpose

    call multiply

    call trace

    mov rdi, output
    mov rsi, rax
    call printf

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
    imul r10, r9
    add r10, r9

    mov r11, r9
    imul r11, r8
    add r11, r8

    mov r12, [matX + r10 * 8]
    mov [matXT + r11 * 8], r12

    inc r9
    cmp r9, [n]
    jl .column_loop

    inc r8
    cmp r8, [m]
    jl .row_loop

    ret


multiply:
    xor r8, r8 ; i = 0
.row_loop: 
    xor r9, r9 ; j = 0
.column_loop:
    xor r10, r10 ; k = 0
.intersection_loop:
    mov r11, r8
    imul r11, [n] ; row * columns
    add r11, r10 ; + column

    mov r12, r10
    imul r12, [m] ; row * columns
    add r12, r9 ; + column

    mov r13, r8
    imul r13, [m] ; row * columns
    add r13, r9 ; + column

    mov r14, [matXT + r11 * 8] ; A[i][k]
    imul r14, [matY + r12 * 8] ; A[i][k] * B[k][j]
    add [matZ + r13 * 8], r14 ; add to the result

    inc r10 ; k++
    cmp r10, [n]
    jl .intersection_loop

    inc r9 ; j++
    cmp r9, [m]
    jl .column_loop

    inc r8 ; i++
    cmp r8, [m]
    jl .row_loop

    ret

trace:
    xor r8, r8
    xor rax, rax
.loop:
    mov r9, r8
    imul r9, [m]
    add r9, r8

    add rax, [matZ + r9 * 8]

    inc r8
    cmp r8, [m]
    jl .loop

    ret
