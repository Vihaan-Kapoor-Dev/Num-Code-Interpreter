bits 64
default rel

%ifndef SAFE_MODE
%define SAFE_MODE 0
%endif

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

section .rdata
align 8
program:
    incbin "program_v2.bin"
string_pool:
    incbin "strings_v2.bin"
newline db 10
align 8
dispatch_table:
    dq op_halt,op_seti,op_addi,op_subi,op_muli,op_divi,op_powi
    dq op_print_reg,op_print_imm,op_print_str,op_jmp,op_jz,op_jnz
    dq op_jlt8,op_jgt8,op_jeq8,op_add_jlt_reg,op_sub_jnz,op_movr,op_addr

section .bss
align 16
variables resd 26
number_buffer resb 16
stdout_handle resq 1
written_count resd 1

section .text
global main
extern GetStdHandle
extern WriteFile
extern ExitProcess

main:
    sub rsp, 40
    mov ecx, -11
    call GetStdHandle
    mov [stdout_handle], rax
    lea rsi, [program]
    lea r15, [dispatch_table]
    lea rbx, [variables]
    NEXT

op_halt:
    xor ecx, ecx
    call ExitProcess

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
    mov rsi, r8
    call platform_write
    lea rsi, [newline]
    mov edx, 1
    call platform_write
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

write_u32_newline:
    push rsi
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
    call platform_write
    pop rsi
    ret

platform_write:
    sub rsp, 40
    mov r8d, edx
    mov rdx, rsi
    mov rcx, [stdout_handle]
    lea r9, [written_count]
    mov qword [rsp+32], 0
    call WriteFile
    add rsp, 40
    ret

op_divzero:
    mov ecx, 3
    call ExitProcess

op_bad:
    mov ecx, 2
    call ExitProcess
