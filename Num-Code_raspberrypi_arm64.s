.equ MAX_OPCODE, 19

.macro NEXT
ldrb w0, [x19]
add x19, x19, #8
ldr x1, [x25, w0, uxtw #3]
br x1
.endm

.section .rodata
.p2align 3
program:
.incbin "program_v2.bin"
string_pool:
.incbin "strings_v2.bin"
newline:
.byte 10
.p2align 3
dispatch_table:
.xword op_halt,op_seti,op_addi,op_subi,op_muli,op_divi,op_powi
.xword op_print_reg,op_print_imm,op_print_str,op_jmp,op_jz,op_jnz
.xword op_jlt8,op_jgt8,op_jeq8,op_add_jlt_reg,op_sub_jnz,op_movr,op_addr

.section .bss
.p2align 4
variables:
.skip 104
number_buffer:
.skip 16

.section .text
.p2align 2
.global _start
_start:
adrp x19, program
add x19, x19, :lo12:program
adrp x20, variables
add x20, x20, :lo12:variables
adrp x25, dispatch_table
add x25, x25, :lo12:dispatch_table
NEXT

op_halt:
mov w0, wzr
mov x8, #93
svc #0

op_seti:
ldurb w1, [x19, #-7]
ldur w0, [x19, #-4]
str w0, [x20, w1, uxtw #2]
NEXT

op_addi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
add w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_subi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
sub w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_muli:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
mul w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_divi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
cbz w2, op_divzero
ldr w0, [x20, w1, uxtw #2]
udiv w0, w0, w2
str w0, [x20, w1, uxtw #2]
NEXT

op_powi:
ldurb w1, [x19, #-7]
ldur w2, [x19, #-4]
ldr w0, [x20, w1, uxtw #2]
mov w3, #1
1:
cbz w2, 3f
tbz w2, #0, 2f
mul w3, w3, w0
2:
mul w0, w0, w0
lsr w2, w2, #1
b 1b
3:
str w3, [x20, w1, uxtw #2]
NEXT

op_print_reg:
ldurb w1, [x19, #-7]
ldr w0, [x20, w1, uxtw #2]
bl write_u32_newline
NEXT

op_print_imm:
ldur w0, [x19, #-4]
bl write_u32_newline
NEXT

op_print_str:
ldurb w2, [x19, #-7]
ldursw x3, [x19, #-4]
adrp x1, string_pool
add x1, x1, :lo12:string_pool
add x1, x1, x3
bl platform_write
adrp x1, newline
add x1, x1, :lo12:newline
mov x2, #1
bl platform_write
NEXT

op_jmp:
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
NEXT

op_jz:
ldurb w1, [x19, #-7]
ldr w0, [x20, w1, uxtw #2]
cbnz w0, 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jnz:
ldurb w1, [x19, #-7]
ldr w0, [x20, w1, uxtw #2]
cbz w0, 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jlt8:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
cmp w0, w2
b.hs 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jgt8:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
cmp w0, w2
b.ls 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_jeq8:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
cmp w0, w2
b.ne 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_add_jlt_reg:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldurb w3, [x19, #-5]
ldr w0, [x20, w1, uxtw #2]
add w0, w0, w3
str w0, [x20, w1, uxtw #2]
ldr w4, [x20, w2, uxtw #2]
cmp w0, w4
b.hs 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_sub_jnz:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
subs w0, w0, w2
str w0, [x20, w1, uxtw #2]
b.eq 1f
ldursw x0, [x19, #-4]
add x19, x19, x0, lsl #3
1:
NEXT

op_movr:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w2, uxtw #2]
str w0, [x20, w1, uxtw #2]
NEXT

op_addr:
ldurb w1, [x19, #-7]
ldurb w2, [x19, #-6]
ldr w0, [x20, w1, uxtw #2]
ldr w3, [x20, w2, uxtw #2]
add w0, w0, w3
str w0, [x20, w1, uxtw #2]
NEXT

write_u32_newline:
stp x29, x30, [sp, #-16]!
adrp x1, number_buffer
add x1, x1, :lo12:number_buffer
add x1, x1, #15
mov w2, #10
strb w2, [x1]
mov w3, #1
mov w4, #10
1:
udiv w5, w0, w4
msub w6, w5, w4, w0
sub x1, x1, #1
add w6, w6, #48
strb w6, [x1]
add w3, w3, #1
mov w0, w5
cbnz w0, 1b
uxtw x2, w3
bl platform_write
ldp x29, x30, [sp], #16
ret

platform_write:
mov x0, #1
mov x8, #64
svc #0
ret

op_divzero:
mov w0, #3
mov x8, #93
svc #0

op_bad:
mov w0, #2
mov x8, #93
svc #0
