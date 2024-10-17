.data
gridsize:   .byte 8,8 #not a hard-coded value, format is (row, column)
player:  .byte 0,0
box:        .byte 0,0
target:     .byte 0,0

#for random: (DO NOT CHANGE)
a: .word 6
c: .word 1
m: .word 25
seed: .word 100 #will be manipulated as the game progresses

space_char: .byte ' '

wall_char: .byte '.' #. or X
empty_square_char: .byte '_' #. or _
player_char: .byte 'p'
box_char: .byte 'b'
target_char: .byte 't'
box_on_target_char: .byte '*'

#settings
#allows player, box, and target to potentially spawn on boundary squares
allow_boundary_spawn: .byte 1 #0 for true, 1 for false


newline: .string "\n"
clash: .string "location clash\n"

.text
.globl _start

_start:
    # TODO: Generate locations for the player, box, and target. Static
    # locations in memory have been provided for the (x, y) coordinates 
    # of each of these elements.
    #
    # There is a notrand function that you can use to start with. It's 
    # really not very good; you will replace it with your own rand function
    # later. Regardless of the source of your "random" locations, make 
    # sure that none of the items are on top of each other and that the 
    # board is solvable.

    jal gen_locations



    

   
    # TODO: Now, print the gameboard. Select symbols to represent the walls,
    # player, box, and target. Write a function that uses the location of
    # the various elements (in memory) to construct a gameboard and that 
    # prints that board one player at a time.
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

gen_locations:
    #storing original values on stack
    addi sp, sp, -12
    sw ra, 8(sp)
    sw s0, 4(sp)
    sw s1, 0(sp)


    #locations may be on boundaries
    la t0, allow_boundary_spawn
    lb t0, 0(t0)

    #row
    la s0, gridsize
    lb s0, 0(s0)
    sub s0, s0, t0
    #column
    la s1, gridsize
    lb s1, 1(s1)
    sub s1, s1, t0
    

    gen_locations_player:
        mv a0, s0
        jal rand

        #updating player x (row) coordinate
        la t0, player
        sb a0, 0(t0)

        mv a0, s1
        jal rand
        
        #updating player y (column) coordinate
        la t0, player
        sb a0, 1(t0)

    gen_locations_box:
        #TODO remove
        la a0, clash
        li a7, 4
        ecall
        #

        mv a0, s0
        jal rand

        #updating box x (row) coordinate
        la t0, box
        sb a0, 0(t0)

        mv a0, s1
        jal rand
        
        #updating box y (column) coordinate
        la t0, box
        sb a0, 1(t0)

        #checking if box location is equal to player location and fixing if so...
        la a0, box
        la a1, player
        jal check_equal_locations
        beq a0, zero, gen_locations_box

        #TODO: make sure box does not spawn in a corner (because then the player won't be able to move it)


    gen_locations_target:
        #TODO remove
        la a0, clash
        li a7, 4
        ecall
        #

        mv a0, s0
        jal rand

        #updating target x (row) coordinate
        la t0, target
        sb a0, 0(t0)

        mv a0, s1
        jal rand

        #updating target y (column) coordinate
        la t0, target
        sb a0, 1(t0)

        #checking if target location is equal to the box location or player location and fixing if so...
        la a0, target
        la a1, player
        jal check_equal_locations
        beq a0, zero, gen_locations_target
        la a0, target
        la a1, box
        jal check_equal_locations
        beq a0, zero, gen_locations_target
    

    lw s1, 0(sp)
    lw s0, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    jr ra





# Arguments: an integer MAX in a0
# Return: A number from 1 (inclusive) to MAX (exclusive)
# X_n+1 = (a*X_n + c) % m
rand:
    #loading equation parameters
    la t0, a
    lw t0, 0(t0)

    la t1, c
    lw t1, 0(t1)
    
    la t2, m
    lw t2, 0(t2)

    #argument passed to function
    mv t3, a0

    # #getting random seed using time syscall (seed stored in a0)
    # li a7, 30
    # ecall
    # remu a0, a0, t2

    la a0, seed
    lw a0, 0(a0)
    
    mul a0, a0, t0
    add a0, a0, t1
    remu a0, a0, t2

    #update seed BEFORE adjusting for argument
    la t4, seed
    sw a0, 0(t4)

    remu a0, a0, t3
	
    bne a0, zero, rand_end

	li a0, 1

    rand_end:        
        jr ra


#
#####<START> PRINT FUNCTIONS
#

#Arguments: N/A
printBoard:
    #store ra using stack
    addi sp, sp, -4
    sw ra, 0(sp)

    #storing original values of store registers on the stack (because they are callee-saved)
    addi sp, sp, -4
    sw s0, 0(sp)
    addi sp, sp, -4
    sw s1, 0(sp)
    addi sp, sp, -4
    sw s2, 0(sp)
    addi sp, sp, -4
    sw s3, 0(sp)

    #load grid row count
    la s0, gridsize
    lb s0, 0(s0) #rows
    #load grid column count
    la s1, gridsize
    lb s1, 0(s1) #columns


    #nested for loop
    li s2, -1 #row counter (must start at -1 since we allow row count to potentially be 0)
    li s3, 0 #column counter

    printBoard_outerloop:
        addi s2, s2, 1

        beq s2, s0, printBoard_end

        li a0, 2
        jal print_multiple_newlines

        li s3, 0 #resetting column counter
        printBoard_innerloop:
            beq s3, s1, printBoard_outerloop

            #checking what type of object to print (wall, empty_square, player, box, target, box_on_target)
            mv a0, s2
            mv a1, s3
            jal get_object_at_coordinate
            
            jal print_object
            #increment column counter
            addi s3, s3, 1
            j printBoard_innerloop

    printBoard_end:
        jal printNewline
        
        #resetting original values of store registers on the stack (because they are callee-saved)
        #also resetting original value of ra
        lw s3, 0(sp)
        lw s2, 4(sp)
        lw s1, 8(sp)
        lw s0, 12(sp)
        lw ra, 16(sp)

        #popping stack
        addi sp, sp, 20
        jr ra

#argument:
#a0 contains the address of the object to print
print_object:
    li a7, 11
    lb a0, 0(a0)
    ecall

    #3 space chars (to make look symmetrical)
    la a0, space_char
    lb a0, 0(a0)
    ecall
    ecall
    ecall

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


#
#####<END>#####
#


#
#####<START> CHECK EQUAL FUNCTIONS
#

#arguments:
#a0 and a1 are the addresses of the locations in memory
#sets a0 to 0 if locations are equal and to 1 if they are not
check_equal_locations:
    lb t0, 0(a0)
    lb t1, 1(a0)
    lb t2, 0(a1)
    lb t3, 1(a1)

    bne t0, t2, check_equal_locations_1
    bne t1, t3, check_equal_locations_1

    check_equal_locations_0:
        li a0, 0
        jr ra

    check_equal_locations_1:
        li a0, 1
        jr ra

#arguments:
#a0 is address
#a1 and a2 are coordinates (row, column)
#sets a0 to 0 if locations are equal and to 1 if they are not
check_equal_location_coordinate:
    lb t0, 0(a0)
    lb t1, 1(a0)
    mv t2, a1
    mv t3, a2

    bne t0, t2, check_equal_location_coordinate_1
    bne t1, t3, check_equal_location_coordinate_1

    check_equal_location_coordinate_0:
        li a0, 0
        jr ra

    check_equal_location_coordinate_1:
        li a0, 1
        jr ra

#arguments:
#a0 and a1 are the first set of coordinates (row, column)
#a2 and a3 are the second set of coordinates (row, column)
#sets a0 to 0 if locations are equal and to 1 if they are not
check_equal_coordinates:
    mv t0, a0
    mv t1, a1
    mv t2, a2
    mv t3, a3

    bne t0, t2, check_equal_coordinates_1
    bne t1, t3, check_equal_coordinates_1

    check_equal_coordinates_0:
        li a0, 0
        jr ra

    check_equal_coordinates_1:
        li a0, 1
        jr ra

#
#####<END>#####
#

#arguments:
#a0 and a1 are the set of coordinates (row, column)
#sets a0 to the appropriate address of the char byte (labels ending in "_char")
get_object_at_coordinate:
    #storing ra on stack
    addi sp, sp, -4
    sw ra, 0(sp)
    #storing original values of s0, s1 on the stack (because they are callee-saved)
    addi sp, sp, -4
    sw s0, 0(sp)
    addi sp, sp, -4
    sw s1, 0(sp)

    #order is important
    mv a2, a1
    mv a1, a0

    #note: s0 will be used to store address of the char (because after the jal call, a0 will be overwritten)

    #here we begin
    ################## 1
    la a0, player
    la s0, player_char
    jal check_equal_location_coordinate
    beq a0, zero, get_object_at_coordinate_end
    ################## 2
    la a0, box
    la s0, box_char
    jal check_equal_location_coordinate
    beq a0, zero, get_object_at_coordinate_end
    ################## 3
    la a0, target
    la s0, target_char
    jal check_equal_location_coordinate
    beq a0, zero, get_object_at_coordinate_end
    ################## 4
    #TODO: change this but for now, we assume everything else is a wall
    
    #wall only at boundaries (first and last rows and columns)
    
    la s0, wall_char

    get_object_at_coordinate_end:
        mv a0, s0
        #resetting original values of s0, s1 on the stack (because they are callee-saved)
        #also resetting original value of ra
        lw s1, 0(sp)
        lw s0, 4(sp)
        lw ra, 8(sp)

        #popping stack
        addi sp, sp, 12

        jr ra