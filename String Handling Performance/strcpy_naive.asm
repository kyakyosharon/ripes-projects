.data
    .align 4
src_str:
    .string "RISC-V Architecture is Powerful! This is a long string used to demonstrate the performance difference between byte-by-byte copy and SWAR optimized copy."
    .align 4
dst_buf:
    .space 256

.text
.globl main
main:
    la a0, dst_buf
    la a1, src_str

    call strcpy_naive

    li a7, 10
    ecall

# void strcpy_naive(char *dst, const char *src)
.global strcpy_naive
strcpy_naive:
    lb t0, 0(a1)          # src[i]
    sb t0, 0(a0)          # dst[i]
    beqz t0, end_naive
    addi a0, a0, 1
    addi a1, a1, 1
    j strcpy_naive

end_naive:
    ret
