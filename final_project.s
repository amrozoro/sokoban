.data
gridsize:   .byte 8,8 #not a hard-coded value
character:  .byte 0,0
box:        .byte 0,0
target:     .byte 0,0

wall_char: .byte 'w'
player_char: .byte 'p'
box_char: .byte 'b'
target_char: .byte 't'
box_on_target_char: .byte 'X'

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




    # li s0, 0 #to exit randomLoop
    # jal randomLoop
    # la a0, loopCompletedString
    # li a7, 4
    # ecall
    

    jal printBoard


exit:
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---
# Feel free to use, modify, or add to them however you see fit.

randomLoop:
    mv s11, ra

	randomLoopBody:
        li a7, 5
        ecall

    	beq a0, s0, randomLoopEnd

		jal notrand
		li a7, 1
		ecall

        jal printNewline

		j randomLoopBody
    	
    randomLoopEnd:
        lw ra, 0(s1)
        jr ra


#Arguments: N/A
printBoard:
    #store ra using sbrk
    li a0, 4
    li a7, 9
    ecall
    mv s11, a0 #moving address to a store register (s11, the last store register)
    sw ra, 0(s11)

    #load grid dimensions
    la t0, gridsize
    lb s0, 0(t0) #rows
    lb s1, 1(t0) #columns

    #nested for loop
    li t0, 0 #row counter
    li t1, 0 #column counter

    #load wall char
    la s2, wall_char
    lb s2, 0(s2)

    printBoard_outerloop:
        beq t0, s0, printBoard_end

        addi t0, t0, 1
        jal printNewline

        printBoard_innerloop:
            beq t1, s1, printBoard_outerloop

            mv a0, s2
            li a7, 11
            ecall
            
            #increment column counter
            addi t1, t1, 1

            j printBoard_innerloop

    printBoard_end:
        jal printNewline

        mv ra, s11
        jr ra






printNewline:
    la a0, newline
    li a7, 4
    ecall
    jr ra

# Arguments: an integer MAX in a0
# Return: A number from 0 (inclusive) to MAX (exclusive)
notrand:
    mv t0, a0
    li a7, 30
    ecall             # time syscall (returns milliseconds)
    remu a0, a0, t0   # modulus on bottom bits 
    li a7, 32
    ecall             # sleeping to try to generate a different number
    jr ra
