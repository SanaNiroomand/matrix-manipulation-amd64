%define SIZE 256

section .bss
    matX    resq SIZE         ; reserve space for matrix X
    matY    resq SIZE         ; reserve space for matrix Y
    matZ    resq SIZE         ; reserve space for matrix Z = XY
    matXT   resq SIZE         ; reserve space for matrix X transpose

    m       resq 1            ; rows of X or columns of Y
    n       resq 1            ; columns of X or rows of Y

section .data
    dimensions: db "%lld %lld", 0
    element_in: db "%lld", 0
    output:     db "%lld", 0

extern scanf
extern printf

section .text
    global main

main:
    push rbp 
    mov rbp, rsp          ; stack alignment

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

    ; Instead of the original sequence:
    ;    call transpose
    ;    call multiply
    ;    call trace
    ; we now use our inner_product_unrolled routine
    call inner_product_unrolled

    mov rdi, output
    mov rsi, rax        ; result is in rax
    call printf         ; print the output

    xor rax, rax        ; return 0
    leave               ; stack alignment
    ret

read_matrix:
    ; inputs: rax = matrix pointer, rbx = row, rcx = column
    xor r8, r8          ; set row iterator to zero
    
.row_loop:
    xor r9, r9          ; set column iterator to zero
.column_loop:
    mov r10, r8
    imul r10, rcx       ; row * columns
    add r10, r9         ; + column
    
    ; input element
    mov rdi, element_in
    lea rsi, [rax + r10 * 8]
    push rax            ; push needed register before being changed by call
    push rbx
    push rcx
    push r8
    push r9
    call scanf

    pop r9              ; pop the registers
    pop r8
    pop rcx
    pop rbx
    pop rax

    inc r9             ; increase column iterator
    cmp r9, rcx
    jl .column_loop

    inc r8             ; increase row iterator
    cmp r8, rbx
    jl .row_loop

    ret

; ---------------------------------------------------------------------------
; inner_product_unrolled:
;   Computes the inner product (sum of element-wise products) of matrices X and Y
;   using loop unrolling (processing 4 elements per iteration).
;   It assumes 64-bit values (each element is 8 bytes).
; ---------------------------------------------------------------------------
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
    xor rax, rax      ; clear accumulator (result in rax)

.unrolled_loop:
    cmp r13, 0
    je .remainder     ; if no more groups, jump to remainder processing

    ; Process 4 elements per iteration.
    mov r9, [matX + r8*8]
    mov r10, [matY + r8*8]
    imul r9, r10
    add rax, r9

    mov r9, [matX + (r8+1)*8]
    mov r10, [matY + (r8+1)*8]
    imul r9, r10
    add rax, r9

    mov r9, [matX + (r8+2)*8]
    mov r10, [matY + (r8+2)*8]
    imul r9, r10
    add rax, r9

    mov r9, [matX + (r8+3)*8]
    mov r10, [matY + (r8+3)*8]
    imul r9, r10
    add rax, r9

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
    mov r9, [matX + r8*8]
    mov r10, [matY + r8*8]
    imul r9, r10
    add rax, r9
    inc r8
    dec r13
    jmp .tail_loop

.done:
    ret