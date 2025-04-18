.data
#---Pseudo random number generator algorithm citation:---
#PRNG name: Linear congruential generator
#Published in 1958 by W. E. Thomson and A. Rotenberg.
#Link: https://en.wikipedia.org/wiki/Linear_congruential_generator
#Useful YT video: https://www.youtube.com/watch?v=kRCmR4qr-hQ&t=1s

#function is located under the "rand" label (last function)

#---Enhancements:
#1) Multiplayer - mostly in functions setup, getplayercount, playerloop and updateleaderboard
#2) Undo - mostly in functions setup, setupheap, playerloop, and move


#parameters for random: (DO NOT CHANGE)
a: .word 6
c: .word 1
m: .word 25
seed: .word 100 #chosen randomly, will be manipulated as the game progresses

sleep_factor_board: .word 250 #how much time to sleep before printing board again (in ms)
sleep_factor_turn: .word 2000 #how much time to sleep before switching turn to next player (in ms)

#heap stuff

#address (represented as an integer) of the move count of first (or only) player
MOVE_COUNT_HEAP_START: .word 0x10000000

#address (represented as an integer) of the first move of the current (or only) player.
#This will be dynamically calculated to be directly after MOVE_COUNT_HEAP_START (which is why it is 0 for now)
MOVE_HISTORY_HEAP_START: .word 0

#integer representing the number of moves currently logged in history
#(remember that each undo removes the latest move in the history and decreases the NUM_MOVES_IN_HISTORY)
NUM_MOVES_IN_HISTORY: .word 0

#integer representing the size (in bytes) of one move stored in memory
MOVE_MEMORY_SIZE: .word 8

#NOTE:
# every move takes up exactly MOVE_MEMORY_SIZE bytes in memory and is represented by the:
#1. move number (.word), this may not be (previous move's move number + 1) because of the fact that undo exists
#2. location of player (.byte x 2)
#3. location of box (.byte x 2)
#and in that specific order


#Multiplayer stuff
NUM_PLAYERS: .word 0
current_player_turn: .word 0 #player number


#leaderboard (least num of moves)
leaderboard: .word 0, 0, 0


#board stuff
gridsize:   .byte 8,8 #not a hard-coded value, format is (row, column)
player:  .byte 0,0
box:        .byte 0,0
target:     .byte 0,0

#player, box, target initial locations
player_initial: .byte 0,0
box_initial: .byte 0,0
target_initial: .byte 0,0

space_char: .byte ' '

#object chars
wall_char: .byte 'X' #. or X
empty_square_char: .byte '.' #. or _
player_char: .byte 'P'
box_char: .byte 'B'
target_char: .byte '$' #t or * or $
box_on_target_char: .byte '*'

#settings
#allows player, box, and target to potentially spawn on boundary squares
allow_boundary_spawn: .byte 1 #0 for true, 1 for false

#north,east,south,west,restart,exit
input_controls: .byte 0, 1, 2, 3, 4, 5
input_controls_count: .byte 6

#strings
newline: .string "\n"
semicolon: .string ": "
prompt: .string "> "
clash: .string "location clash\n"
invalid_input_string: .string "Invalid input...try again\n"
illegal_move_string: .string "Cannot perform that move...try again\n" #illegal moves are ones like trying to go through a wall or pushing a box with a wall behind it
restart_notice_string: .string "*************************\n*****RESTARTING GAME*****\n*************************"
congrats_message_string: .string "Congrats! You have completed the game!\n"
input_controls_string: .string "\n**CONTROLS**\n0: north\n1: east\n2: south\n3: west\n4: restart to original position\n5: exit game\n6: undo\n"
player_count_prompt_string: .string "Enter the number of players (> 0): "
player_count_error_string: .string "Error: Player count must be greater than 0\n"
player_number_label: .string "\nPLAYER "
player_on_target_string: .string "\nAlert: You are standing on the target square\n"

leaderboard_first_string: .string "\nFirst place number of moves: "
leaderboard_second_string: .string "\nSecond place number of moves: "
leaderboard_third_string: .string "\nThird place number of moves: "

.text
.globl _start

_start:
    jal setup
    
    jal gen_locations

    jal player_loop

    j exit

game:
    #storing on stack
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw s0, 0(sp)
    addi sp, sp, -4
    sw s1, 0(sp)

    j game_loop
    
    game_loop:
        la a0, prompt
        li a7, 4
        ecall

        #input
        li a7, 5
        ecall

        #input can be (for default input controls) 0(north), 1(east), 2(south), 3(west), -1(restart to original position), -2(exit)...anything else and we print a warning
        la t0, input_controls
        
        #offsets in s0 and s1

        li s0, -1
        li s1, 0
        lb t1, 0(t0)
        beq a0, t1, try_move

        li s0, 0
        li s1, 1
        lb t1, 1(t0)
        beq a0, t1, try_move
        
        li s0, 1
        li s1, 0
        lb t1, 2(t0)
        beq a0, t1, try_move
        
        li s0, 0
        li s1, -1
        lb t1, 3(t0)
        beq a0, t1, try_move
        
        lb t1, 4(t0)
        beq a0, t1, restart_game
        
        lb t1, 5(t0)
        beq a0, t1, game_end

        #any other input gets redirected to warning
        jal print_invalid_input_warning
        j game_loop

        try_move:
            #offsets
            mv a0, s0
            mv a1, s1

            jal move

            #check if game ended
            beq a0, zero, game_end

            j game_loop
 
    restart_game:
        jal print_restart_notice
        jal load_initial_positions
        jal printBoard
        j game_loop


    game_end:
        lw s1, 0(sp)
        lw s0, 4(sp)
        lw ra, 8(sp)
        addi sp, sp, 12
        jr ra

exit:
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---
setup:
    addi sp, sp, -4
    sw ra, 0(sp)

    jal get_player_count
    jal setup_heap

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


get_player_count:
    la a0, player_count_prompt_string
    li a7, 4
    ecall

    li a7, 5
    ecall

    li t0, 1

    blt a0, t0, get_player_count

    la t0, NUM_PLAYERS
    sw a0, 0(t0)

    jr ra


setup_heap:
    la t0, MOVE_COUNT_HEAP_START
    lw t0, 0(t0) #address
    la t1, MOVE_HISTORY_HEAP_START
    lw t1, 0(t1) #address
    la t2, NUM_PLAYERS
    lw t2, 0(t2)
    li t3, 4 #size of word in bytes

    # need to calculate address of MOVE_HISTORY_HEAP_START
    mul t4, t2, t3 #offset

    add t5, t0, t4
    la t1, MOVE_HISTORY_HEAP_START
    sw t5, 0(t1)

    jr ra


player_loop:
    addi sp, sp, -4
    sw ra, 0(sp)

    player_loop_begin:
        jal print_controls

        #print label to show player number
        la a0, player_number_label
        li a7, 4
        ecall
        la a0, current_player_turn
        lw a0, current_player_turn
        li a7, 1
        ecall
        la a0, newline
        li a7, 4
        ecall

        #sleep
        la a0, sleep_factor_turn
        lw a0, 0(a0)
        li a7, 32
        ecall

        jal load_initial_positions
        jal printBoard
        jal game
        jal update_leaderboard

        #increment player turn
        la t0, current_player_turn
        lw t1, 0(t0)
        addi t1, t1, 1
        sw t1, 0(t0)

        la t2, NUM_PLAYERS
        lw t2, 0(t2)
        blt t1, t2, player_loop_begin

    jal print_leaderboard
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


update_leaderboard:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, current_player_turn
    lw t0, 0(t0)
    mv a0, t0
    jal get_num_moves

    la a1, leaderboard
    lw t1, 0(a1)
    lw t2, 4(a1)
    lw t3, 8(a1)

    bgt a0, t1, update_leaderboard_first
    bgt a0, t2, update_leaderboard_second
    bgt a0, t3, update_leaderboard_third

    j update_leaderboard_end

    update_leaderboard_first:
        la t0, leaderboard
        sw a0, 0(t0)
        sw t1, 4(t0)
        sw t2, 8(t0)
        j update_leaderboard_end
    update_leaderboard_second:
        la t0, leaderboard
        sw a0, 4(t0)
        sw t2, 8(t0)
        j update_leaderboard_end
    update_leaderboard_third:
        la t0, leaderboard
        sw a0, 8(t0)
        j update_leaderboard_end
    update_leaderboard_end:
        lw ra, 0(sp)
        addi sp, sp, 4
        jr ra


#arguments:
#a0 stores player number [0 to NUM_PLAYERS-1]
#sets a0 to appropriate move count of player
get_num_moves:
    li t1, 4
    mul t1, a0, t1 #byte offset
    
    la t0, MOVE_COUNT_HEAP_START
    lw t0, 0(t0)
    add t0, t0, t1

    lw a0, 0(t0) #current number of moves

    jr ra


#arguments:
#a0 stores player number [0 to NUM_PLAYERS-1]
increment_move_counter:
    li t1, 4
    mul t1, a0, t1 #byte offset
    
    la t0, MOVE_COUNT_HEAP_START
    lw t0, 0(t0)
    add t0, t0, t1

    lw t1, 0(t0) #current number of moves
    addi t1, t1, 1
    sw t1, 0(t0)

    jr ra



gen_locations:
    #storing original values on stack
    addi sp, sp, -12
    sw ra, 8(sp)
    sw s0, 4(sp)
    sw s1, 0(sp)

    #locations may be on boundaries
    la t0, allow_boundary_spawn
    lb t0, 0(t0)

    #max row
    la s0, gridsize
    lb s0, 0(s0)
    sub s0, s0, t0
    #max column
    la s1, gridsize
    lb s1, 1(s1)
    sub s1, s1, t0
    
    gen_locations_box:
        # #TODO remove/comment out
        # la a0, clash
        # li a7, 4
        # ecall
        # #

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

        #making sure box does not spawn in a corner (because then the player won't be able to move it)
        la t0, box
        lb a0, 0(t0)
        lb a1, 1(t0)
        jal is_corner

        beq a0, zero, gen_locations_box



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

        #checking if player location is equal to box location and fixing if so...
        la a0, player
        la a1, box
        jal check_equal_locations
        beq a0, zero, gen_locations_player


    gen_locations_target:
        # #TODO remove/comment out
        # la a0, clash
        # li a7, 4
        # ecall
        # #

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

        #making sure player can actually move the box to the target...
        #there are cases where the box is adjacent to a boundary wall (but not in a corner)
        #yet no combination of moves can move the box to the target square
        la a0, box
        lb a0, 0(a0)
        jal is_adjacent_to_horizontal_boundaries
        beq a0, zero, gen_locations_target_h
        
        la a0, box
        lb a0, 1(a0)
        jal is_adjacent_to_vertical_boundaries
        beq a0, zero, gen_locations_target_v

        j gen_locations_end

        gen_locations_target_h:
            la t0, box
            lb t0, 0(t0)
            la t1, target
            lb t1, 0(t1)
            bne t0, t1, gen_locations_target

            j gen_locations_end

        gen_locations_target_v:
            la t0, box
            lb t0, 1(t0)
            la t1, target
            lb t1, 1(t1)
            bne t0, t1, gen_locations_target

            j gen_locations_end
    

    gen_locations_end:
        jal store_initial_positions
        lw s1, 0(sp)
        lw s0, 4(sp)
        lw ra, 8(sp)
        addi sp, sp, 12
        jr ra


#a0 is row offset, a1 is column offset
#returns 0 if move resulted in box being placed on target (game completed) and 1 otherwise
move:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw s0, 0(sp)
    addi sp, sp, -4
    sw s1, 0(sp)
    addi sp, sp, -4
    sw s2, 0(sp)
    addi sp, sp, -4
    sw s3, 0(sp)

    #player's coordinates
    la t0, player
    lb t1, 0(t0) #row
    lb t2, 1(t0) #column
    
    #saving offsets
    mv s2, a0
    mv s3, s1

    #dest coordinates
    add s0, t1, a0
    add s1, t2, a1

    #find what block is at dest
    mv a0, s0
    mv a1, s1
    jal get_object_at_coordinate

    #check if the object is a wall
    la t0, wall_char
    beq a0, t0, dest_wall

    #check if the object is an empty square or target square (which is technically an empty square and will be regarded as such)
    la t0, empty_square_char
    beq a0, t0, dest_empty_square
    la t0, target_char
    beq a0, t0, dest_target_square

    #check if the object is a box
    la t0, box_char
    beq a0, t0, dest_box

    j move_end

    dest_wall:
        jal print_illegal_move_warning
        j move_end
        
    dest_target_square:
        la a0, player_on_target_string
        li a7, 4
        ecall
    dest_empty_square:
        la a0, player
        mv a1, s0
        mv a2, s1
        jal update_object_location

        #wait a little then print board
        la a0, sleep_factor_board
        lw a0, 0(a0)
        li a7, 32
        ecall

        #print updated board
        jal printBoard

        j move_successful
    
    dest_box:
        #check that there is room for the box to move by offsetting the dest
        add a0, s0, s2 #s0 is row number of dest, s2 is row offset
        add a1, s1, s3
        jal get_object_at_coordinate

        la t0, wall_char
        beq a0, t0, no_room #there's a wall behind the box

        #case if there is room - update player and box locations
        la a0, player
        mv a1, s0
        mv a2, s1
        jal update_object_location
        
        la a0, box
        add a1, s0, s2
        add a2, s1, s3
        jal update_object_location


        #check if box is on target
        la a0, box
        la a1, target
        jal check_equal_locations
        beq a0, zero, completed

        #wait a little then print board
        la a0, sleep_factor_board
        lw a0, 0(a0)
        li a7, 32
        ecall
        
        #print updated board
        jal printBoard

        j move_successful

        no_room:
            jal print_illegal_move_warning
            j move_end

        completed:
            jal print_congrats_message
            li a0, 0
            j move_end
        

    move_successful: #move successful (but game not completed)
        la a0, current_player_turn
        lw a0, 0(a0)
        jal increment_move_counter

        li a0, 1 #to indicate game not completed yet
    move_end:
        lw s3, 0(sp)
        lw s2, 4(sp)
        lw s1, 8(sp)
        lw s0, 12(sp)
        lw ra, 16(sp)
        addi sp, sp, 20
        jr ra


#a0 is object's address, a1 is new row, a2 is new column
update_object_location:
    sb a1, 0(a0)
    sb a2, 1(a0)
    jr ra


store_initial_positions:
    la t0, player_initial
    la t1, player
    lb t2, 0(t1)
    sb t2, 0(t0)
    lb t2, 1(t1)
    sb t2, 1(t0)
    
    la t0, box_initial
    la t1, box
    lb t2, 0(t1)
    sb t2, 0(t0)
    lb t2, 1(t1)
    sb t2, 1(t0)
    
    la t0, target_initial
    la t1, target
    lb t2, 0(t1)
    sb t2, 0(t0)
    lb t2, 1(t1)
    sb t2, 1(t0)

    jr ra

load_initial_positions:
    la t0, player_initial
    la t1, player
    lb t2, 0(t0)
    sb t2, 0(t1)
    lb t2, 1(t0)
    sb t2, 1(t1)
    
    la t0, box_initial
    la t1, box
    lb t2, 0(t0)
    sb t2, 0(t1)
    lb t2, 1(t0)
    sb t2, 1(t1)
    
    la t0, target_initial
    la t1, target
    lb t2, 0(t0)
    sb t2, 0(t1)
    lb t2, 1(t0)
    sb t2, 1(t1)

    jr ra


#arguments: N/A (the locations of each object is stored in the global data segment)
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

    #load grid row and column count
    la t0, gridsize
    lb s0, 0(t0) #rows
    lb s1, 1(t0) #columns


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


print_controls:
    la a0, input_controls_string
    li a7, 4
    ecall
    jr ra


#argument:
#a0 (number of newlines), assumed to be > 0
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


print_invalid_input_warning:
    la a0, invalid_input_string
    li a7, 4
    ecall
    jr ra

print_illegal_move_warning:
    la a0, illegal_move_string
    li a7, 4
    ecall
    jr ra

print_restart_notice:
    la a0, restart_notice_string
    li a7, 4
    ecall
    jr ra
print_congrats_message:
    la a0, congrats_message_string
    li a7, 4
    ecall
    jr ra


print_leaderboard:
    la t0, leaderboard
    
    la a0, leaderboard_first_string
    li a7, 4
    ecall
    lw a0, 0(t0)
    li a7, 1
    ecall
    la a0, newline
    li a7, 4
    ecall
    
    la a0, leaderboard_second_string
    li a7, 4
    ecall
    lw a0, 4(t0)
    li a7, 1
    ecall
    la a0, newline
    li a7, 4
    ecall
    
    la a0, leaderboard_third_string
    li a7, 4
    ecall
    lw a0, 8(t0)
    li a7, 1
    ecall
    la a0, newline
    li a7, 4
    ecall


    jr ra


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
    #wall only at boundaries (first and last rows and columns)    
    la s0, wall_char
    jal is_boundary
    beq a0, zero, get_object_at_coordinate_end
    ################## 5
    #everything else is an empty square (including target)
    la s0, empty_square_char


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

#arguments:
#a1 and a2 are the set of coordinates (row, column)
#sets a0 to 0 if true and 1 if false
is_boundary:
    la t0, gridsize
    lb t0, 0(t0)
    addi t0, t0, -1 #max row

    la t1, gridsize
    lb t1, 1(t1)
    addi t1, t1, -1 #max column

    #check if a1 is 0 or max row (if it is, we jump straight to the end)
    beq a1, zero, is_boundary_0
    beq a1, t0, is_boundary_0
    #check if a2 is 0 or max column (if it is, we jump straight to the end)
    beq a2, zero, is_boundary_0
    beq a2, t1, is_boundary_0

    j is_boundary_1

    is_boundary_0:
        li a0, 0
        jr ra

    is_boundary_1:
        li a0, 1
        jr ra

#arguments:
#a0 and a1 are the set of coordinates (row, column)
#sets a0 to 0 if true and 1 if false
is_corner:
    #storing on stack
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw s0, 0(sp)
    addi sp, sp, -4
    sw s1, 0(sp)
    addi sp, sp, -4
    sw s2, 0(sp)
    addi sp, sp, -4
    sw s3, 0(sp)

    mv s0, a0        
    mv s1, a1

    la t0, gridsize
    lb s2, 0(t0) #r
    lb s3, 1(t0) #c

    mv a0, s0
    mv a1, s1
    li a2, 1
    li a3, 1
    jal check_equal_coordinates
    beq a0, zero, is_corner_0
    
    mv a0, s0
    mv a1, s1
    li a2, 1
    addi a3, s3, -2
    jal check_equal_coordinates
    beq a0, zero, is_corner_0

    mv a0, s0
    mv a1, s1
    addi a2, s2, -2
    li a3, 1
    jal check_equal_coordinates
    beq a0, zero, is_corner_0

    mv a0, s0
    mv a1, s1
    addi a2, s2, -2
    addi a3, s3, -2
    jal check_equal_coordinates
    beq a0, zero, is_corner_0

    j is_corner_1

    is_corner_0:
        li a0, 0
        j is_corner_end

    is_corner_1:
        li a0, 1
        j is_corner_end

    is_corner_end:
        #popping stack
        lw s3, 0(sp)
        lw s2, 4(sp)
        lw s1, 8(sp)
        lw s0, 12(sp)
        lw ra, 16(sp)
        addi sp, sp, 20

        jr ra

#arguments:
#a0 is the row coordinate
#sets a0 to 0 if true and 1 if false
is_adjacent_to_horizontal_boundaries:
    la t0, gridsize
    lb t0, 0(t0)
    addi t0, t0, -2

    li t1, 1

    beq a0, t1, is_adjacent_to_horizontal_boundaries_0
    beq a0, t0, is_adjacent_to_horizontal_boundaries_0
    

    is_adjacent_to_horizontal_boundaries_1:
        li a0, 1
        jr ra
    is_adjacent_to_horizontal_boundaries_0:
        li a0, 0
        jr ra

#arguments:
#a0 is the column coordinate
#sets a0 to 0 if true and 1 if false
is_adjacent_to_vertical_boundaries:
    la t0, gridsize
    lb t0, 1(t0)
    addi t0, t0, -2

    li t1, 1

    beq a0, t1, is_adjacent_to_vertical_boundaries_0
    beq a0, t0, is_adjacent_to_vertical_boundaries_0
    

    is_adjacent_to_vertical_boundaries_1:
        li a0, 1
        jr ra
    is_adjacent_to_vertical_boundaries_0:
        li a0, 0
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