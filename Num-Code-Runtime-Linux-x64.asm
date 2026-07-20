bits 64
default rel

%ifndef SAFE_MODE
%define SAFE_MODE 0
%endif

%define OP_HALT 0
%define OP_SETI 1
%define OP_ADDI 2
%define OP_SUBI 3
%define OP_MULI 4
%define OP_DIVI 5
%define OP_POWI 6
%define OP_PRINT_REG 7
%define OP_PRINT_IMM 8
%define OP_PRINT_STR 9
%define OP_JMP 10
%define OP_JZ 11
%define OP_JNZ 12
%define OP_JLT8 13
%define OP_JGT8 14
%define OP_JEQ8 15
%define OP_ADD_JLT_REG 16
%define OP_SUB_JNZ 17
%define OP_MOVR 18
%define OP_ADDR 19
%define OP_IMPORT 20
%define OP_CALL0 21
%define OP_CALL1 22
%define OP_CALL2 23
%define MAX_OPCODE 23

%macro NEXT 0
    movzx eax, byte [rsi]
    add rsi, 8
%if SAFE_MODE
    cmp eax, MAX_OPCODE
    ja op_bad
%endif
    jmp [r15 + rax*8]
%endmacro

section .rodata
align 8
program:
    incbin "Num-Code.bin"
string_pool:
    incbin "Num-Code-Strings.bin"
newline db 10
align 8
dispatch_table:
    dq op_halt
    dq op_seti
    dq op_addi
    dq op_subi
    dq op_muli
    dq op_divi
    dq op_powi
    dq op_print_reg
    dq op_print_imm
    dq op_print_str
    dq op_jmp
    dq op_jz
    dq op_jnz
    dq op_jlt8
    dq op_jgt8
    dq op_jeq8
    dq op_add_jlt_reg
    dq op_sub_jnz
    dq op_movr
    dq op_addr
    dq op_import
    dq op_call0
    dq op_call1
    dq op_call2

section .bss
align 16
variables resd 26
number_buffer resb 16
print_iov resq 4
loaded_modules resd 1
random_state resd 1
timespec_buffer resq 2
input_buffer resb 64

section .text
global main
extern num_code_external_import
extern num_code_external_call0
extern num_code_external_call1
extern num_code_external_call2

main:
    sub rsp, 8
    lea rsi, [program]
    lea r15, [dispatch_table]
    lea rbx, [variables]
    mov dword [random_state], 0xA341316C
    NEXT

op_halt:
    xor eax, eax
    add rsp, 8
    ret

op_seti:
    movzx ecx, byte [rsi-7]
    mov eax, [rsi-4]
    mov [rbx+rcx*4], eax
    NEXT

op_addi:
    movzx ecx, byte [rsi-7]
    mov eax, [rsi-4]
    add [rbx+rcx*4], eax
    NEXT

op_subi:
    movzx ecx, byte [rsi-7]
    mov eax, [rsi-4]
    sub [rbx+rcx*4], eax
    NEXT

op_muli:
    movzx ecx, byte [rsi-7]
    mov eax, [rbx+rcx*4]
    imul eax, [rsi-4]
    mov [rbx+rcx*4], eax
    NEXT

op_divi:
    mov eax, [rsi-4]
    test eax, eax
    jz op_divzero
    movzx ecx, byte [rsi-7]
    mov r8d, eax
    mov eax, [rbx+rcx*4]
    xor edx, edx
    div r8d
    mov [rbx+rcx*4], eax
    NEXT

op_powi:
    movzx ecx, byte [rsi-7]
    mov eax, [rbx+rcx*4]
    mov r8d, [rsi-4]
    mov edx, 1
.p:
    test r8d, r8d
    jz .done
    test r8b, 1
    jz .square
    imul edx, eax
.square:
    imul eax, eax
    shr r8d, 1
    jmp .p
.done:
    mov [rbx+rcx*4], edx
    NEXT

op_print_reg:
    movzx ecx, byte [rsi-7]
    mov eax, [rbx+rcx*4]
    call write_u32_newline
    NEXT

op_print_imm:
    mov eax, [rsi-4]
    call write_u32_newline
    NEXT

op_print_str:
    movzx edx, byte [rsi-7]
    movsxd rax, dword [rsi-4]
    lea r8, [string_pool+rax]
    mov r14, rsi
    lea r10, [print_iov]
    mov [r10], r8
    mov [r10+8], rdx
    lea rax, [newline]
    mov [r10+16], rax
    mov qword [r10+24], 1
    mov eax, 20
    mov edi, 1
    mov rsi, r10
    mov edx, 2
    syscall
    mov rsi, r14
    NEXT

op_jmp:
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
    NEXT

op_jz:
    movzx ecx, byte [rsi-7]
    cmp dword [rbx+rcx*4], 0
    jne .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jnz:
    movzx ecx, byte [rsi-7]
    cmp dword [rbx+rcx*4], 0
    je .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jlt8:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    cmp [rbx+rcx*4], edx
    jae .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jgt8:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    cmp [rbx+rcx*4], edx
    jbe .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_jeq8:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    cmp [rbx+rcx*4], edx
    jne .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_add_jlt_reg:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    movzx r8d, byte [rsi-5]
    mov eax, [rbx+rcx*4]
    add eax, r8d
    mov [rbx+rcx*4], eax
    cmp eax, [rbx+rdx*4]
    jae .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_sub_jnz:
    movzx ecx, byte [rsi-7]
    movzx eax, byte [rsi-6]
    sub [rbx+rcx*4], eax
    jz .n
    movsxd rax, dword [rsi-4]
    lea rsi, [rsi+rax*8]
.n:
    NEXT

op_movr:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    mov eax, [rbx+rdx*4]
    mov [rbx+rcx*4], eax
    NEXT

op_addr:
    movzx ecx, byte [rsi-7]
    movzx edx, byte [rsi-6]
    mov eax, [rbx+rdx*4]
    add [rbx+rcx*4], eax
    NEXT


op_import:
    movzx ecx, byte [rsi-7]
    cmp ecx, 255
    je .all
    cmp ecx, 128
    jae .external
    cmp ecx, 1
    jb op_bad_module
    cmp ecx, 4
    ja op_bad_module
    bts dword [loaded_modules], ecx
    NEXT
.external:
    cmp ecx, 254
    ja op_bad_module
    mov edi, ecx
    push rsi
    sub rsp, 8
    call num_code_external_import
    add rsp, 8
    pop rsi
    test eax, eax
    jnz op_external_error
    NEXT
.all:
    mov dword [loaded_modules], 0x1E
    NEXT

op_call0:
    movzx r12d, byte [rsi-7]
    cmp r12d, 25
    ja op_bad_register
    movzx r10d, byte [rsi-6]
    movzx r11d, byte [rsi-5]
    cmp r10d, 128
    jae .external
    cmp r10d, 1
    jb op_bad_module
    cmp r10d, 4
    ja op_bad_module
    bt dword [loaded_modules], r10d
    jnc op_not_imported
    cmp r10d, 2
    je .random
    cmp r10d, 3
    je .time
    cmp r10d, 4
    je .input
    jmp op_bad_function
.external:
    cmp r10d, 254
    ja op_bad_module
    push rsi
    sub rsp, 8
    mov edi, r10d
    mov esi, r11d
    call num_code_external_call0
    add rsp, 8
    pop rsi
    mov rdx, rax
    shr rdx, 32
    test edx, edx
    jnz op_external_call_error
    mov [rbx+r12*4], eax
    NEXT
.random:
    cmp r11d, 1
    jne op_bad_function
    call random_next
    mov [rbx+r12*4], eax
    NEXT
.time:
    cmp r11d, 1
    jne op_bad_function
    call time_millis
    mov [rbx+r12*4], eax
    NEXT
.input:
    cmp r11d, 1
    jne op_bad_function
    call read_u32
    mov [rbx+r12*4], eax
    NEXT

op_call1:
    movzx r12d, byte [rsi-7]
    cmp r12d, 25
    ja op_bad_register
    movzx r10d, byte [rsi-6]
    movzx r11d, byte [rsi-5]
    movzx r8d, byte [rsi-4]
    cmp r8d, 25
    ja op_bad_register
    cmp r10d, 128
    jae .external
    cmp r10d, 1
    jb op_bad_module
    cmp r10d, 4
    ja op_bad_module
    bt dword [loaded_modules], r10d
    jnc op_not_imported
    mov eax, [rbx+r8*4]
    cmp r10d, 1
    je .math
    cmp r10d, 2
    je .random
    jmp op_bad_function
.external:
    cmp r10d, 254
    ja op_bad_module
    push rsi
    sub rsp, 8
    mov edi, r10d
    mov esi, r11d
    mov edx, [rbx+r8*4]
    call num_code_external_call1
    add rsp, 8
    pop rsi
    mov rdx, rax
    shr rdx, 32
    test edx, edx
    jnz op_external_call_error
    mov [rbx+r12*4], eax
    NEXT
.math:
    cmp r11d, 1
    je .sqrt
    cmp r11d, 5
    je .popcount
    jmp op_bad_function
.sqrt:
    call math_isqrt
    mov [rbx+r12*4], eax
    NEXT
.popcount:
    call math_popcount
    mov [rbx+r12*4], eax
    NEXT
.random:
    cmp r11d, 3
    jne op_bad_function
    test eax, eax
    jnz .seed_ok
    mov eax, 0xA341316C
.seed_ok:
    mov [random_state], eax
    mov [rbx+r12*4], eax
    NEXT

op_call2:
    movzx r12d, byte [rsi-7]
    cmp r12d, 25
    ja op_bad_register
    movzx r10d, byte [rsi-6]
    movzx r11d, byte [rsi-5]
    movzx r8d, byte [rsi-4]
    movzx r9d, byte [rsi-3]
    cmp r8d, 25
    ja op_bad_register
    cmp r9d, 25
    ja op_bad_register
    cmp r10d, 128
    jae .external
    cmp r10d, 1
    jb op_bad_module
    cmp r10d, 4
    ja op_bad_module
    bt dword [loaded_modules], r10d
    jnc op_not_imported
    cmp r10d, 1
    je .math
    cmp r10d, 2
    je .random
    jmp op_bad_function
.external:
    cmp r10d, 254
    ja op_bad_module
    push rsi
    sub rsp, 8
    mov edi, r10d
    mov esi, r11d
    mov edx, [rbx+r8*4]
    mov ecx, [rbx+r9*4]
    call num_code_external_call2
    add rsp, 8
    pop rsi
    mov rdx, rax
    shr rdx, 32
    test edx, edx
    jnz op_external_call_error
    mov [rbx+r12*4], eax
    NEXT
.math:
    cmp r11d, 2
    je .gcd
    cmp r11d, 3
    je .min
    cmp r11d, 4
    je .max
    jmp op_bad_function
.gcd:
    mov eax, [rbx+r8*4]
    mov edx, [rbx+r9*4]
    call math_gcd
    mov [rbx+r12*4], eax
    NEXT
.min:
    mov eax, [rbx+r8*4]
    mov edx, [rbx+r9*4]
    cmp eax, edx
    cmova eax, edx
    mov [rbx+r12*4], eax
    NEXT
.max:
    mov eax, [rbx+r8*4]
    mov edx, [rbx+r9*4]
    cmp eax, edx
    cmovb eax, edx
    mov [rbx+r12*4], eax
    NEXT
.random:
    cmp r11d, 2
    jne op_bad_function
    mov r10d, [rbx+r8*4]
    mov r11d, [rbx+r9*4]
    cmp r11d, r10d
    jbe .range_low
    call random_next
    mov ecx, r11d
    sub ecx, r10d
    xor edx, edx
    div ecx
    lea eax, [rdx+r10]
    mov [rbx+r12*4], eax
    NEXT
.range_low:
    mov [rbx+r12*4], r10d
    NEXT

op_external_call_error:
    mov eax, edx
op_external_error:
    add eax, 20
    add rsp, 8
    ret

random_next:
    mov eax, [random_state]
    test eax, eax
    jnz .go
    mov eax, 0xA341316C
.go:
    mov edx, eax
    shl edx, 13
    xor eax, edx
    mov edx, eax
    shr edx, 17
    xor eax, edx
    mov edx, eax
    shl edx, 5
    xor eax, edx
    mov [random_state], eax
    ret

math_isqrt:
    mov r8d, eax
    xor eax, eax
    mov edx, 0x40000000
.align:
    cmp edx, r8d
    jbe .loop
    shr edx, 2
    jmp .align
.loop:
    test edx, edx
    jz .done
    lea ecx, [eax+edx]
    cmp r8d, ecx
    jb .no_sub
    sub r8d, ecx
    shr eax, 1
    add eax, edx
    jmp .next
.no_sub:
    shr eax, 1
.next:
    shr edx, 2
    jmp .loop
.done:
    ret

math_popcount:
    xor edx, edx
.loop:
    test eax, eax
    jz .done
    lea ecx, [eax-1]
    and eax, ecx
    inc edx
    jmp .loop
.done:
    mov eax, edx
    ret

math_gcd:
.loop:
    test edx, edx
    jz .done
    xor ecx, ecx
    mov ecx, edx
    xor edx, edx
    div ecx
    mov eax, ecx
    jmp .loop
.done:
    ret

time_millis:
    mov r14, rsi
    mov eax, 228
    mov edi, 1
    lea rsi, [timespec_buffer]
    syscall
    mov rsi, r14
    test eax, eax
    js op_platform_error
    mov r8, [timespec_buffer]
    imul r8, r8, 1000
    mov rax, [timespec_buffer+8]
    xor edx, edx
    mov ecx, 1000000
    div rcx
    add rax, r8
    ret

read_u32:
    mov r14, rsi
    xor eax, eax
    xor edi, edi
    lea rsi, [input_buffer]
    mov edx, 64
    syscall
    mov rsi, r14
    test rax, rax
    jle .zero
    mov rcx, rax
    lea rdi, [input_buffer]
    xor eax, eax
    xor r8d, r8d
.loop:
    movzx edx, byte [rdi]
    inc rdi
    cmp edx, 48
    jb .not_digit
    cmp edx, 57
    ja .not_digit
    imul eax, eax, 10
    sub edx, 48
    add eax, edx
    mov r8d, 1
    dec rcx
    jnz .loop
    ret
.not_digit:
    test r8d, r8d
    jnz .done
    dec rcx
    jnz .loop
.zero:
    xor eax, eax
.done:
    ret

write_u32_newline:
    mov r14, rsi
    lea rsi, [number_buffer+15]
    mov byte [rsi], 10
    mov r10d, 1
    mov ecx, 10
.c:
    xor edx, edx
    div ecx
    dec rsi
    add dl, 48
    mov [rsi], dl
    inc r10d
    test eax, eax
    jnz .c
    mov edx, r10d
    mov eax, 1
    mov edi, 1
    syscall
    mov rsi, r14
    ret

op_divzero:
    mov eax, 3
    add rsp, 8
    ret

op_bad:
    mov eax, 2
    add rsp, 8
    ret


op_bad_module:
    mov eax, 10
    add rsp, 8
    ret

op_not_imported:
    mov eax, 11
    add rsp, 8
    ret

op_bad_function:
    mov eax, 12
    add rsp, 8
    ret

op_bad_register:
    mov eax, 13
    add rsp, 8
    ret

op_platform_error:
    mov eax, 14
    add rsp, 8
    ret
