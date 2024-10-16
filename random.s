.data
a: .word 6
c: .word 1
m: .word 25
start_seed: .word 10

newline: .string "\n"

.text
.globl _start

_start:
    la a1, start_seed
    lw a1, 0(a1)
    
    li t3, 10

    loop:
	    jal rand

        remu a0, a1, t3
        li a7, 1
        ecall
                
        li a7, 5
        ecall
        
        j loop

	

#seed passed in as a1
#X_n+1 = (a*X_n + c) % m
rand:
    la t0, a
    lw t0, 0(t0)

    la t1, c
    lw t1, 0(t1)
    
    la t2, m
    lw t2, 0(t2)
    
    mul a1, a1, t0
    add a1, a1, t1
    remu a1, a1, t2
	
	ret

exit:
    li a7, 10
    ecall