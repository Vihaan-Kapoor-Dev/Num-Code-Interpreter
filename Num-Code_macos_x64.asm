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
%define MAX_OPCODE 19

%macro NEXT 0
    movzx eax, byte [rsi]
    add rsi, 8
%if SAFE_MODE
    cmp eax, MAX_OPCODE
    ja op_bad
%endif
    jmp [r15 + rax*8]
%endmacro

section __TEXT,__const
align 8
program:
    incbin "program_v2.bin"
string_pool:
    incbin "strings_v2.bin"
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

section __DATA,__bss
align 16
variables resd 26
number_buffer resb 16
print_iov resq 4

section __TEXT,__text
global _main
extern _write
extern _exit

_main:
    lea rsi, [program]
    lea r15, [dispatch_table]
    lea rbx, [variables]
    NEXT

op_halt:
    xor edi, edi
    sub rsp, 8
    call _exit

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
    lea r8, [string_pool]
    add r8, rax
    call write_string_newline
    NEXT

write_string_newline:
    mov r14, rsi
    mov edi, 1
    mov rsi, r8
    call _write
    mov edi, 1
    lea rsi, [newline]
    mov edx, 1
    call _write
    mov rsi, r14
    ret

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
    mov edi, 1
    call _write
    mov rsi, r14
    ret

op_divzero:
    mov edi, 3
    sub rsp, 8
    call _exit

op_bad:
    mov edi, 2
    sub rsp, 8
    call _exit
