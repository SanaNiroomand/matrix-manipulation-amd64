%define SIZE 256

section .data
    ; reserve 64-bit doubles for matrices    
    matX: times SIZE dq 0.0
    matY: times SIZE dq 0.0

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

    call inner_product_unrolled

    mov rdi, output
    mov rsi, rax        ; result is in rax
    mov rax, 1
    call printf         ; print the output

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

inner_product_unrolled:
    ; Calculate total number of elements = m * n.
    mov rax, [m]      ; load m (number of rows)
    mov rbx, [n]      ; load n (number of columns)
    imul rax, rbx     ; rax = m * n (total number of elements)
    mov r12, rax      ; save total in r12

    ; Determine how many groups of 4 elements exist.
    mov r13, r12
    shr r13, 2        ; r13 = total / 4

    xor r8, r8        ; index = 0
    pxor xmm0, xmm0   ; clear accumulator (result in xmm0)

.unrolled_loop:
    cmp r13, 0
    je .remainder     ; if no more groups, jump to remainder processing

    ; Process 4 elements per iteration.
    movsd xmm1, [matX + r8*8]
    movsd xmm2, [matY + r8*8]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1

    movsd xmm1, [matX + (r8+1)*8]
    movsd xmm2, [matY + (r8+1)*8]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1

    movsd xmm1, [matX + (r8+2)*8]
    movsd xmm2, [matY + (r8+2)*8]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1

    movsd xmm1, [matX + (r8+3)*8]
    movsd xmm2, [matY + (r8+3)*8]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1

    add r8, 4         ; processed 4 elements, so increase index by 4
    dec r13           ; decrement group counter
    jmp .unrolled_loop

.remainder:
    ; Process any remaining elements (if total number of elements mod 4 != 0).
    mov r13, r12
    and r13, 3       ; r13 = total mod 4 (number of remaining elements)
.tail_loop:
    cmp r13, 0
    je .done
    movsd xmm1, [matX + r8*8]
    movsd xmm2, [matY + r8*8]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1
    inc r8
    dec r13
    jmp .tail_loop

.done:
    movq rax, xmm0
    ret