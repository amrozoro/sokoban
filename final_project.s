.data
gridsize:   .byte 8,8 #not a hard-coded value
character:  .byte 0,0
box:        .byte 0,0
target:     .byte 0,0

#for random:
a: .word 6
c: .word 1
m: .word 25
start_seed: .word 10

space_char: .byte ' '
wall_char: .byte 'X'
player_char: .byte 'p'
box_char: .byte 'b'
target_char: .byte 't'
box_on_target_char: .byte '*'

newline: .string "\n"
loopCompletedString: .string "randomLoop has completed"
randNumString: .string ""

.text
.globl _start

_start:
    # TODO: Generate locations for the character, box, and target. Static
    # locations in memory have been provided for the (x, y) coordinates 
    # of each of these elements.
    # 
    # There is a notrand function that you can use to start with. It's 
    # really not very good; you will replace it with your own rand function
    # later. Regardless of the source of your "random" locations, make 
    # sure that none of the items are on top of each other and that the 
    # board is solvable.
   
    # TODO: Now, print the gameboard. Select symbols to represent the walls,
    # character, box, and target. Write a function that uses the location of
    # the various elements (in memory) to construct a gameboard and that 
    # prints that board one character at a time.
    # HINT: You may wish to construct the string that represents the board
    # and then print that string with a single syscall. If you do this, 
    # consider whether you want to place this string in static memory or 
    # on the stack. 

    # TODO: Enter a loop and wait for user input. Whenever user input is
    # received, update the gameboard state with the new location of the 
    # player (and if applicable, box and target). Print a message if the 
    # input received is invalid or if it results in no change to the game 
    # state. Otherwise, print the updated game state. 
    #
    # You will also need to restart the game if the user requests it and 
    # indicate when the box is located in the same position as the target.
    # For the former, it may be useful for this loop to exist in a function,
    # to make it cleaner to exit the game loop.

    # TODO: That's the base game! Now, pick a pair of enhancements and
    # consider how to implement them.

    

    jal printBoard

    j exit


exit:
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---




#Arguments: N/A
printBoard:
    #store ra using stack
    addi sp, sp, -4
    sw ra, 0(sp)

    #nested for loop
    li s0, -1 #row counter (must start at -1 since we allow row count to potentially be 0)
    li s1, 0 #column counter

    printBoard_outerloop:
        addi s0, s0, 1

        #load grid width
        la t0, gridsize
        lb t0, 0(t0) #rows

        beq s0, t0, printBoard_end

        li a0, 2
        jal print_multiple_newlines

        li s1, 0 #resetting column counter
        printBoard_innerloop:
            #load grid length
            la t0, gridsize
            lb t0, 1(t0) #columns

            beq s1, t0, printBoard_outerloop

            #printing chars
            li a7, 11

            #wall
            la a0, wall_char
            lb a0, 0(a0)
            ecall

            #3 space chars (to make look symmetrical)
            la a0, space_char
            lb a0, 0(a0)
            ecall
            ecall
            ecall
            
            #increment column counter
            addi s1, s1, 1

            j printBoard_innerloop

    printBoard_end:
        jal printNewline

        lw ra, 0(sp)
        addi sp, sp, 4
        jr ra






printNewline:
    la a0, newline
    li a7, 4
    ecall
    jr ra

# argument: a0 (number of newlines), assumed to be > 0
print_multiple_newlines:
    li t0, 0 #counter
    mv t1, ra
    mv t2, a0

    print_multiple_newlines_loop:
        jal printNewline
        
        addi t0, t0, 1
        beq t0, t2, print_multiple_newlines_end
        
        j print_multiple_newlines_loop

    print_multiple_newlines_end:
        mv ra, t1
        jr ra


# Arguments: an integer MAX in a0
# Return: A number from 0 (inclusive) to MAX (exclusive)
# seed passed in as a1
# X_n+1 = (a*X_n + c) % m
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

    remu a0, a1, a0
	
	ret