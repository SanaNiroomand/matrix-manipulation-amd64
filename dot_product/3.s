%define SIZE 256

section .data
    ; reserve 64-bit doubles for matrices    
    matX: times SIZE dq 0.0
    matT: times SIZE dq 0.0
    matZ: times SIZE dq 0.0
    matY: times SIZE dq 0.0
    matXT: times SIZE dq 0.0

    m: dq 0 ; rows of A
    n: dq 0 ; columns of A and rows of B

    dimensions: db "%lld %lld", 0
    element_in: db "%lf", 0
    output: db "%.2lf", 0

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

    call transposeX

    call transpose

    call multiply_matrices

    call trace

    mov rdi, output
    mov rsi, rax
    mov rax, 1
    call printf ; print the output

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

transposeX:
    xor r8, r8
.row_loop:
    xor r9, r9
.column_loop:
    mov r10, r8
    imul r10, [n]
    add r10, r9

    mov r11, r9
    imul r11, [m]
    add r11, r8

    mov r12, [matX + r10 * 8]
    mov [matXT + r11 * 8], r12 ; transpose logic

    inc r9
    cmp r9, [n]
    jl .column_loop

    inc r8
    cmp r8, [m]
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
    imul r11, [m]
    add r11, r8

    mov r12, [matY + r10 * 8]
    mov [matT + r11 * 8], r12 ; transpose logic

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
    cmp     r10, [m]
    jge     .finish_dot

    ; If only one element remains, do a scalar multiply
    mov r12, [m]
    sub r12, r10
    cmp r12, 1
    je  .scalar_dot

    ; load 2 elements from A[i][k]
    mov r11, r8
    imul r11, [m] ; row * columns
    add r11, r10  ; + column
    movupd xmm1, [matXT + r11 * 8] ; A[i][k:k+1]

    ; load 2 elements from T[k][j]
    mov r11, r9
    imul r11, [m] ; row * columns
    add r11, r10  ; + column
    movupd xmm2, [matT + r11 * 8] ; T[k][j:j+1]

    mulpd xmm1, xmm2
    addpd xmm0, xmm1

    add r10, 2 ; k += 2 processing two doubles at a time
    cmp r10, [m]
    jl .intersection_loop
    jmp .finish_dot

.scalar_dot:
    ; Process the last element using scalar instructions.
    mov r11, r8
    imul r11, [m]
    add r11, r10
    movsd xmm1, [matXT + r11 * 8]

    mov r11, r9
    imul r11, [m]
    add r11, r10
    movsd xmm2, [matT + r11 * 8]

    mulsd xmm1, xmm2
    addsd xmm0, xmm1
    inc r10
    jmp .intersection_loop

.finish_dot:
    ; Horizontally add the 2 doubles in xmm0 to produce a single scalar.
    movhlps xmm1, xmm0        ; xmm1 = high 64 bits of xmm0 (the second double)
    addsd   xmm0, xmm1        ; xmm0[0] = xmm0[0] + xmm1[0]

    mov r11, r8
    imul r11, [n] ; row * columns
    add r11, r9  ; + column
    movsd [matZ + r11 * 8], xmm0 ; store the result in C[i][j]

    inc r9 ; j++
    cmp r9, [n]
    jl .column_loop

    inc r8 ; i++
    cmp r8, [n]
    jl .row_loop

    ret

trace:
    pxor xmm0, xmm0       ; clear xmm0 (set accumulator to 0.0)
    xor r8, r8            ; set loop index = 0
.trace_loop:
    mov r9, r8
    imul r9, [n]         ; r9 = r8 * n
    add r9, r8           ; r9 = r8*n + r8 (diagonal index)
    movsd xmm1, [matZ + r9 * 8]  ; load diagonal element (as double)
    addsd xmm0, xmm1     ; add to accumulator
    inc r8
    cmp r8, [n]
    jl .trace_loop
    movq rax, xmm0       ; move the final double result into rax
    ret
