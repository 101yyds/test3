    .global _start
    .section text
_start:
.text
    lu12i.w     $t0,-0x7fc00    # A = 0x80400 000
    lu12i.w     $t1,-0x7fb00    # B = 0x80500 000
    lu12i.w     $t2,-0x7fa00    # C = 0x80600 000
    lu12i.w     $a1,-0x7fb00    # lim = 0x80500 000
loop:
    ld.w        $t4,$t0,0x0     # load from array A[i]
    ld.w        $t5,$t1,0x0     # load from array B[i]
    mod.wu      $t3,$t4,$t5     # t3 = t4 % t5
    st.w        $t3,$t2,0x0     # store to array C[i]
    addi.w      $t0,$t0,0x4     # +4
    addi.w      $t1,$t1,0x4     # +4
    addi.w      $t2,$t2,0x4     # +4
    bne         $t0,$a1,loop    # counter neq lim
    
    jirl        $zero,$ra,0x0
