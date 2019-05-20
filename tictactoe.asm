   .data
currentState:	.asciiz	"This is the current state of the GameBoard:\n"
playerOne:	.asciiz	"Player One won\n"
playerTwo:	.asciiz	"Player Two won\n"
playerNone:	.asciiz	"No winners found\n"
enterMove:	.asciiz	"\nEnter a board position (0-8) to make move:\n"
invalidMove:	.asciiz	"\nInvalid move - try again.\n"

CR:		.byte	'\n
SPACE:		.byte	0x20
O:		.byte	'o
X:		.byte	'x
DOT:		.byte	'.
player:		.byte	0x01
gameBoard:	.byte	0,0,0,0,0,0,0,0,0	# fresh clean empty gameboard

		.text
##########################################################################
# MAIN
##########################################################################

main:
	la 	$s0,gameBoard
mainloop:
	lb	$s1,player
	jal 	PrintBoard		# Print the board
	jal	RequestMove		# request the move						
	addu	$t5,$s0,$v0		# apply the move to the board & toggle player
	sb	$s1,0($t5)
	jal 	TogglePlayer
	jal	CheckForWin		# check for win
	bnez	$v0,result
	jal	CheckForMoreMoves	# check for more moves
	bnez	$v0,mainloop		# loop until win or draw		
result:		
	la	$a0,playerNone		
	beqz	$v0,exit
	la	$a0,playerOne
	bgtz	$v0,exit
	la	$a0,playerTwo
exit:	
	li 	$v0,4	
	syscall				# if no winners found, say so and exit	
	jal 	PrintBoard		# print the board one last time before exiting
	li 	$v0,10
	syscall				# exit
										
##########################################################################
# CheckTriplet
#			Check the gameboard positions matching the triplet passed in
#			to determine either player has won that specific triplet.
#
# Input:
#			$a0 : first position to check on gameboard
#			$a1 : second position to check on gameboard
#			$a2 : third position to check on gameboard
#
# Output:
#			$v0 : 0 	= no winner found
#			$v0 : 1 	= player one won
#			$v0 : -1 	= player two won
#			AS WELL AS an appropriate message if player one or player two has won
#
##########################################################################

CheckTriplet:
	la $t0,gameBoard        # load the address of the gameBoard
        addu $t1,$t0,$a0       # offset to first location
	lb $t2,0($t1)           # load the value at first location
        addu $t1,$t0,$a1       # offset to Second location
	lb $t3,0($t1)           # load the value at Second location
        addu $t1,$t0,$a2       # offset to third location
	lb $t4,0($t1)           # load the value at third location
          
        addu $t0,$t2,$t3       # add all the three values
        addu $t0,$t0,$t4
                  
        li $v0,-1               # player two won
        beq $t0,-3,done        # exit if true
          
        li $v0,1                # player one won
        beq $t0,3,done         # exit if true
          
        li $v0,0                # else return zero
         
done:	jr $ra              # return from the function


##########################################################################
# CheckForWin
#	Invoke CheckTriplet against the 8 possible winning combinations
#	to determine if anyone has won the game yet
#		row 0
#		row 1
#		row 2
#		col 0
#		col 1
#		col 2
#		diagonal 0
#		diagonal 1
#
# Output:
#		$v0 : 0 = no winner found
#		$v0 : 1 = player one won
#		$v0 : -1= player two won
##########################################################################

CheckForWin:	
	addi $sp,$sp,-16		# make room on the stack for our variables
	sw   	$ra,0($sp)         	# save our return address
        sw   	$a0,4($sp)
        sw   	$a1,8($sp)
        sw	$a2,12($sp)

	li   	$a0,0			# set the argument triplet for row 0
	li	$a1,1
	li	$a2,2
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more

	li	$a0,3			# set the argument triplet for row 1
	li	$a1,4
	li	$a2,5
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more

	li	$a0,6			# set the argument triplet for row 2
	li	$a1,7
	li	$a2,8
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more
				
	li	$a0,0			# set the argument triplet for col 0
	li	$a1,3
	li	$a2,6
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more

	li	$a0,1			# set the argument triplet for col 1
	li	$a1,4
	li	$a2,7
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more

	li	$a0,2			# set the argument triplet for col 2
	li	$a1,5
	li	$a2,8
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more
               
        li	$a0,0			# set the argument triplet for diag 0
	li	$a1,4
	li	$a2,8
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more

	li	$a0,2			# set the argument triplet for diag 1
	li	$a1,4
	li	$a2,6
	jal	CheckTriplet		# call the function to see if anyone won
	bnez	$v0,doneCFW		# if someone won, don't bother checking more

doneCFW:	
	lw  	$ra,0($sp)         	# restore our return address
        lw   	$a0,4($sp)
        lw   	$a1,8($sp)
        lw   	$a2,12($sp)		
	addi	$sp,$sp,16	     	# free the room we have taken on the stack
	jr	$ra			# return from function

		
##########################################################################
# PRINTBOARD 
##########################################################################

PrintBoard:
	la	$a0,currentState	# display Text
	li 	$v0,4
	syscall	
                    
	la	$t0,gameBoard		# address of the game board
	li	$t6,0x03		# carriage return interval
	li	$t1,0x00		# initial count
                    
plp:	addu	$t3,$t0,$t1		# add offset to the game board address	
	lb	$t4,0($t3)		# load the value
	bltz	$t4,pO			# if < 0 then print 'O'
	bgtz	$t4,pX			# if > 0 then print 'X'
	lb	$a0,DOT			# else print dot	
	li 	$v0,11
	syscall	
	b	pend

pX:	lb	$a0,X			# print 'X'	
	li 	$v0,11
	syscall	
	b	pend

pO:	lb	$a0,O			# print 'O'
	li 	$v0,11
	syscall	
pend:	addi	$t1,$t1,1		# next position
	div	$t1,$t6			# check if it's the end of a row
	mfhi	$t5			# if zero, it is the end of a row
	bnez	$t5,pexit		# otherwise, not
	lb	$a0,CR			# print a CR if it's the end of a row
	li 	$v0,11
	syscall	
	
pexit:	blt	$t1,9,plp		# check all nine position
	jr	$ra			# return from function call

##########################################################################
# RequestMove 
#
# ToDo:
#		return $v0 = player's choice to move to that is valid
#
##########################################################################

RequestMove:
	
	la	$t0,gameBoard       # load the board address
	
	li	$v0,4
	la 	$a0,enterMove		# prompt player
	syscall 
	li	$v0,5
	syscall  			     # read their choice (in $v0)
	move	$t1,$v0
	blt	$t1,0,invalid     # make sure entered value is valid range 0 - 8
	bgt 	$t1,8,invalid
         
        addu   $t0,$t0,$t1  # add offset to the base address
        lb     $t2,0($t0)    # load the value from that location
        beqz   $t2,rdone     # if value is zero then overwrite it
invalid:
        la	$a0,invalidMove # else 
        li	$v0,4
	syscall                  # report error
        b RequestMove         # loop till proper value is entered
rdone:
	move 	$v0,$t1
	jr	$ra			     # return from function call
				
##########################################################################
# CheckForMoreMoves 
#
# ToDo:
#		return $v0 = 0 if no more moves left on gameBoard
#		return $v0 = 1 if yes there are more moves left on gameBoard
#
##########################################################################

CheckForMoreMoves:
		la	$t0,gameBoard
		li	$t1,0x00		# starting index on game board
		li	$v0,0x01		# default is we have more moves
							
ccheck:		addu	$t3,$t0,$t1		# calculate the address of the current position
		lb	$t4,0($t3)		# load the value at the current position
		beqz	$t4,cdone
		addi	$t1,$t1,1		# next index
		blt	$t1,9,ccheck
		li	$v0,0x00		# clear our response to say no more moves
cdone:
		jr	$ra			# return from function call

##########################################################################
# TOGGLEPLAYER
##########################################################################

TogglePlayer:
		lb	$t0,player
		sub	$t0,$zero,$t0
		sb	$t0,player
		jr	$ra						# return from function call
          
