.data
    .align 4                 # Crucial for aligned 32-bit loads
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

    call strcpy_swar

    li a7, 10
    ecall

# void strcpy_swar(char *dst, const char *src)
.global strcpy_swar
strcpy_swar:
    li t1, 0x01010101     # subtractor
    li t2, 0x80808080     # mask

loop_swar:
    lw t0, 0(a1)          # Load 4 bytes

    # SWAR null detection
    # HasZeroByte(v) = (v - 0x01010101) & ~v & 0x80808080
    sub t3, t0, t1        # t3 = X - 0x01010101
    not t4, t0            # t4 = ~X
    and t3, t3, t4
    and t3, t3, t2        # t3 = high bits only

    bnez t3, found_null   # Null exists in this word

    # No null -> copy 4 bytes
    sw t0, 0(a0)
    addi a0, a0, 4
    addi a1, a1, 4
    j loop_swar

found_null:
    # Found a null byte in the current word (t0), copy byte-by-byte until null is hit
    # Note: We could optimize this further by checking which byte is null, 
    # but falling back to byte-copy is simple and correct.
    # We need to re-read from memory or extract bytes from t0. 
    # Re-reading is safer if we want to reuse the naive logic structure.
    
byte_copy_loop:
    lb t5, 0(a1)
    sb t5, 0(a0)
    beqz t5, done
    addi a0, a0, 1
    addi a1, a1, 1
    j byte_copy_loop

done:
    ret
