# Mirror image. Bitmap project. Subash Chandra
.data 0x10000000

strMenuWait: .asciiz "######################### PLEASE WAIT ####################################"
strMenuHr: .asciiz " \n"
strMenuOpts: .asciiz "Select an option: \n"
srtMenuOp1: .asciiz "1 - Reset image \n"
strMenuOp2: .asciiz "2 - Mirror image vertically \n"
strMenuOp3: .asciiz "3 - Mirror image horizontally \n"
strMenuOp4: .asciiz "\n EXTRA FUNCTIONS \n4 - Invert colors \n"
strMenuOp5: .asciiz "5 - Greyscale \n"
strMenuOp6: .asciiz "6 - Exit \n"

openFileErrorStr: .asciiz "Name is incorrect. Program terminating.\n"
readFileErrorStr: .asciiz "file read error. program terminating. \n"
filename: .asciiz "img.bmp"
header: .space 54	#the test bmp has a header of 54 bytes.
.text

# This program only works with 24 bpp UNCOMPRESSED format, so 1 pixel value per 3 bytes. Each pixel value is stored as B,G,R.

main:

	jal loadImage # just storing 2 copies of the image so we can reset the image easily.
	add $s0, $v0, $zero
	add $s1, $v1, $zero

	menuOptsScr:
		li $v0, 4
		la $a0, strMenuHr
		syscall

		li $v0, 4
		la $a0, strMenuOpts
		syscall

		li $v0, 4
		la $a0, srtMenuOp1
		syscall

		li $v0, 4
		la $a0, strMenuOp2
		syscall

		li $v0, 4
		la $a0, strMenuOp3
		syscall

		li $v0, 4
		la $a0, strMenuOp4
		syscall

		li $v0, 4
		la $a0, strMenuOp5
		syscall

		li $v0, 4
		la $a0, strMenuOp6
		syscall

		li $v0, 5
		syscall

		add $t0, $v0, $zero

		li $v0, 4
		la $a0, strMenuWait
		syscall		
		
		beq $t0, 1, resetImageCall
		beq $t0, 2, horizontalFlipCall
		beq $t0, 3, verticalFlipCall
		beq $t0, 4, invertColorsCall
		beq $t0, 5, greyScaleCall
		bgt $t0, 6, endProgram
	#end menuOptsScr

							# Load the options menu screen after every option.
	resetImageCall:
		add $a0, $s0, $zero
		add $a1, $s1, $zero	
		jal dispOriginal								# display Original image call.
		j menuOptsScr									
	#end resetImageCall	
	
	horizontalFlipCall:
		add $a0, $s0, $zero
		la $a1, 0x10008000
		jal horizontalFlip
		j menuOptsScr
	#end rotateXCall

	verticalFlipCall:
		add $a0, $s0, $zero
		la $a1, 0x10008000
		jal verticalFlip
		j menuOptsScr
	#end rotateXCall
	
	
##################################### extra functions ###################################


	invertColorsCall:
		# Using the following equation. You can rotate colors 3 times to get back to the original, but there are quite a few artifacts in the overexposed areas of the image.
		# 	B = (255-B); G = (255-G); R = (255-R);	
		add $a0, $s0, $zero
		la $a1, 0x10008000
		jal invertColors
		j menuOptsScr
	#end invertColorsCall

	greyScaleCall:
		#Using the following equation. 
		#		I = 0.11*B + 0.59*G + 0.30*R	
		#	Use: $a0 and $a1 which are the image properties and data, respectively.		
		add $a0, $s0, $zero
		la $a1, 0x10008000
		jal greyScale
		j menuOptsScr
	#end invertColorsCall

	add $a0, $s0, $zero
	add $a1, $s1, $zero	
	jal endProgram
#end main

##################################################################### NECESSARY FUNCTIONS #################################################################################

printStr:
	li $v0, 4
	syscall
	jr $ra
#end printStr

openFile:
	#sycall for open the file
	li $v0, 13			
	li $a1, 0			# 0 = read, 1 = write.
	li $a2, 0			
	syscall				#returns $v0 = file pointer
	blt $v0, $zero, openFileError
	jr $ra
#end openFile
# bitmap data starts bottom left, goes left to right, bottom to top.
loadImage:
	add $t6, $ra, $zero

	la $a0, filename
	jal openFile
		#$a0 = filename
		#Use: $a0, $a1, $v0. $v0 will return file descriptor
	la $a1, header 		# file header destination address
	li $a2, 54			
	jal readHeader
		#Use: $a0, $a1, $a2, $v0. $a0 will return the hedaer data address
	
	add $t7, $a0, $zero #save file descriptor to store image

	la $a0, header 		#$a0 = read data
	jal analyseHeader 	#call the analyse header function


	jal storeImage
		#Use $a0,1,2 and $t7,8,9 and $v0

	add $a0, $t8, $zero
	add $a1, $t9, $zero
	jal dispOriginal
		#Use $t0-5, $t8-9

	add $v0, $t8, $zero 	#$v0 = data information
	add $v1, $t9, $zero 	#$v1 = data

	add $ra, $t6, $zero
	jr $ra
#end loadImage

dispOriginal:
	la $t0, 0x10008000		#screen address
	lw $t1, 4($a0)
	lw $t2, 8($a0)
	mul $t3, $t1, $t2
	mul $t3, $t3, 4
	add $t0, $t0, $t3 
	mul $t4, $t1, 4
	sub $t0, $t0, $t4
	
	# Saving register
		add $sp, $sp, -12
		add $a0, $sp, $zero
		sw $s0, 0($a0)
		sw $s1, 4($a0)
		sw $s2, 8($a0)
	#s0 will be the iterative width index
	#s1 will be the limit of iterations
	#s2 will be the line break
	mul $t5, $t2, 4 
	li $s0, 0
	mul $s1, $t1, 4
	add $s2, $t5, $t5


	add $t1, $a1, $zero 	#data address
	li $t2, 1 			#index
	add $t3, $zero, 0x10008000
	loop_dispOriginal:
		blt $t0, $t3, end_loop_dispOriginal
		beq $s0, $s1, nextLineDispOriginal

		lb $t4, 0($t1)

		lb $t5, 1($t1)
		sll $t5, $t5, 8
		add $t4, $t4, $t5

		lb $t5, 2($t1)
		sll $t5, $t5, 16
		add $t4, $t4, $t5

		sw $t4, 0($t0)
		add $t1, $t1, 3		
		add $s0, $s0, 4
		add $t0, $t0, 4		
		j loop_dispOriginal		
	end_loop_dispOriginal:
	#end
	#Load Register		
		lw $s0, 0($a0)
		lw $s1, 4($a0)
		lw $s2, 8($a0)
		add $sp, $sp, 12
		
	jr $ra
#end dispOriginal

nextLineDispOriginal:
	li $s0, 0	
	sub $t0, $t0, $s2
j loop_dispOriginal



readHeader:
	move $a0, $v0
	li $v0, 14			
	syscall				# return the number of read characters
	blt $v0, $zero, readFileError
	jr $ra
#end readHeader

analyseHeader:
	la $t0, header

	#dataSave:				LOADING AND SAVING THE HEADER AND IMAGE DATA
		#		0($t8) = Image start address
		# 		4($t8) = pixel width
		#		8($t8) = pixel height

		addi $sp, $sp, -12
		add $t8, $sp, $zero

		#loadWidth:
			#Load each byte and compose int Width
			lb $t1, 18($t0)
			lb $t2, 19($t0)
			sll $t2, $t2, 8
			add $t1, $t1, $t2
			lb $t2, 20($t0)
			sll $t2, $t2, 16
			add $t1, $t1, $t2
			lb $t2, 21($t0)
			sll $t2, $t2, 24
			add $t1, $t1, $t2
		#end loadWidth

		#loadHeight:
			#Load each byte and compose int Height
			lb $t2, 22($t0)
			lb $t3, 23($t0)
			sll $t3, $t3, 8
			add $t2, $t2, $t3
			lb $t3, 24($t0)
			sll $t3, $t3, 16
			add $t2, $t2, $t3
			lb $t3, 25($t0)
			sll $t3, $t3, 24
			add $t2, $t2, $t3
		#end loadHeight		
		
		#loadSize:
			lb $t3, 34($t0)
			lb $t4, 35($t0)
			sll $t4, $t4, 8
			add $t3, $t3, $t4
			lb $t4, 36($t0)
			sll $t4, $t4, 16
			add $t3, $t3, $t4
			lb $t4, 37($t0)
			sll $t4, $t4, 24
			add $t3, $t3, $t4
		#end loadSize	

		#Save obtained values at $t8
		sw $t3, 0($t8)
		sw $t1, 4($t8) # width
		sw $t2, 8($t8) # height

		#Allocate the size of the bitmap of the image in bytes at the stack.
		sub $sp, $sp, $t3
		add $t9, $sp, $zero


	#end dataSave	

	jr $ra

#end analyseHeader


storeImage:
	add $a1, $t9, $zero
	lw $a2, 0($t8)
	add $a0, $t7, $zero
	li $v0, 14			# read file parameter
	syscall				
	blt $v0, $zero, readFileError
	jr $ra
#end storeImage

swapTerms:
	#	Register usage:
	#		a0: address of the first term
	#		a1: address of the second term
	lw $t0, 0($a0)
	lw $t1, 0($a1)
	sw $t1, 0($a0)
	sw $t0, 0($a1)
	jr $ra
#end swapTerms

horizontalFlip:
	#		t7: uper byte 
	#		t8: lower byte

	li $t0, 0				#t0: width index
	lw $t1, 4($a0)				#t1: number of columns
	li $t2, 0				#t2: height index
	lw $t3, 8($a0)				#t3: height/2
	add $t4, $a1, $zero 			#t4: upper byte address
	mul $t5, $t3, $t1		
	mul $t5, $t5, 4		
	add $t5, $t5, $t4			#t5:lower byte address
	add $t5, $t5, -4	
	mul $t7, $t1, 4
	sub $t5, $t5, $t7
	add $t5, $t5, 4			#t5: lower byte address
	mul $t6, $t1, 8			#t6: line break address for the lower byte
	

	div $t3, $t3, 2			#t3: divide height by 2


	loop_horizontalFlip:
		beq $t0, $t1, refreshHorizontalFlip
		beq $t2, $t3, end_loop_horizontalFlip

		lw $t7, 0($t4)
		lw $t8, 0($t5)				#load the two relevant pixels and swap their locations.
		sw $t8, 0($t4)
		sw $t7, 0($t5)

		add $t4, $t4, 4
		add $t5, $t5, 4
		add $t0, $t0, 1		
		j loop_horizontalFlip
	end_loop_horizontalFlip:
	#end

	jr $ra

	refreshHorizontalFlip:
		add $t0, $zero $zero
		add $t2, $t2, 1
		sub $t5, $t5, $t6 
		j loop_horizontalFlip
	#end refreshHorizontalFlip
#end horizontalFlip

verticalFlip:
	
	li $t0, 0				#t0: width index
	lw $t1, 4($a0)				#t1: number of columns
	div $t1, $t1, 2				#divide by 2
	li $t2, 0				#t2: height index
	lw $t3, 8($a0)				#t3: number of rows
	add $t4, $a1, $zero			#t4: upper byte
	mul $t5, $t3, 4				
	add $t6, $t4, $zero
	add $t7, $t4, $t5
	add $t7, $t7, -4
	loop_flixY:
		beq $t2, $t3, end_loop_verticalFlip
		beq $t0, $t1, refreshVerticalFlip		
		lw $t8, 0($t6)				# load the pixels and swap them
		lw $t9, 0($t7)
		sw $t9, 0($t6)
		sw $t8, 0($t7)

		add $t6, $t6, 4
		add $t7, $t7, -4
		add $t0, $t0, 1


		j loop_flixY
	end_loop_verticalFlip:
	#end
	
	jr $ra

	refreshVerticalFlip:
		li $t0, 0
		add $t2, $t2, 1
		add $t4, $t4, $t5
		add $t6, $t4, $zero
		add $t7, $t6, $t5
		add $t7, $t7, -4
		j loop_flixY
	#end refreshVerticalFlip
#end verticalFlip

##################################################################### OPTIONAL FUNCTIONS #############################################################################

greyScale:	

	add $t0, $a0, $zero			#		t0 = data info address
	add $t1, $a1, $zero			#		t1 = data address
	

	la $t2, 0x10008000		#t2: screen start address (iterative)

	lw $t3, 4($t0)			
	lw $t4, 8($t0)			
	mul $t3, $t3, $t4

	li $t4, 1				#t4: iterative index

	#							I = 0.11*B + 0.59*G + 0.30*R
	loop_greyScale:
		beq $t3, $t4, end_loop_greyScale
		
		lbu $t5, 0($t2)
		mul $t5, $t5, 1100				# B*0.11
		div $t5, $t5, 10000
		
		lbu $t6, 1($t2)	 
		mul $t6, $t6, 5900				# G*0.59
		div $t6, $t6, 10000
		add $t5, $t5, $t6
		
		lbu $t7, 2($t2)	
		mul $t7, $t7, 3000				# R*0.30
		div $t7, $t7, 10000
		add $t5, $t5, $t7
		

		add $t6, $t5, $zero
		sll $t6, $t6, 8
		add $t7, $t5, $zero
		sll $t7, $t7, 16

		add $t5,$t5, $t6
		add $t5,$t5, $t7

		sw $t5, 0($t2)

		add $t2, $t2, 4
		add $t4, $t4, 1
		j loop_greyScale
	end_loop_greyScale:		
	#end	

	jr $ra

#end greyScale


invertColors:

	add $t0, $a0, $zero			#		t0: data info address from $a0
	add $t1, $a1, $zero			#		t1: data address from $a1
	li $t9, 255					# 		$t9 = 255. Any value will work here. 255 is for the inverse.

	la $t2, 0x10008000			#		t2: screen start address (iterative)

	lw $t3, 4($t0)				#		pixel height
	lw $t4, 8($t0)				#		pixel width
	mul $t3, $t3, $t4

	li $t4, 1				#		t4: iterative index

	loop_invertColors:
		beq $t3, $t4, end_loop_invertColors
		lb $t5, 0($t2)
		sub $t5, $t9, $t5				# 255 - B
		lb $t6, 1($t2)	
		sub $t6, $t9, $t6				# 255 - G			
		sll $t6, $t6, 8 
		add $t5, $t5, $t6
		lb $t7, 2($t2)	
		sub $t7, $t9, $t7				# 255 - R
		sll $t7, $t7, 16
		add $t5, $t5, $t7
		sw $t5, 0($t2)
		add $t2, $t2, 4
		add $t4, $t4, 1
		j loop_invertColors
	end_loop_invertColors:		
	#end	

	jr $ra
#end invertColors
############################################################## Error throwing ########################################################################
openFileError:
	la $a0, openFileErrorStr
	jal printStr
	jal endProgram
#end openFileError

readFileError:
	#If there are problems in the analyze header section, this will be thrown.
	la $a0, readFileErrorStr
	jal printStr
	jal endProgram
#end readFileError

endProgram:
	lw $t0, 4($a0)
	lw $t1, 8($a0)
	mul $t0, $t0, $t1
	mul $t0, $t0, 4
	add $sp, $sp, $t0
	li $v0, 10
	syscall

