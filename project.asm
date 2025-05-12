# s11, s10 file descriptors. s9, s8 size and offset
# s7, s6 width and height
# s4, s3 address of heaps for pixels and copy
		.data

		.align 2
filename:	.asciz "C:\\studia\\semestr_2\\arko\\page.bmp"
		.align 2
file_end:	.asciz "C:\\studia\\semestr_2\\arko\\page_black.bmp"
		.align 2
header:		.space 124
newline:	.asciz "\n"

	.text
	.globl main

main:
	# Open file to read
	li a7, 1024
	la a0, filename
	li a1, 0
	ecall

	# Print the file descriptor
	li a7, 1
	ecall

	mv s11, a0  # save file descriptor

	# Print debug message
	li a7, 4
	la a0, newline
	ecall
	li a7, 4
	la a0, newline
	ecall

	# Open file to write
	li a7, 1024
	la a0, file_end
	li a1, 1
	ecall

	# Print the file descriptor
	li a7, 1
	ecall

	mv s10, a0  # save file descriptor

	# Print debug message
	li a7, 4
	la a0, newline
	ecall

	# Read header from read_only
	li a7, 63
	mv a0, s11  # file descriptor
	la a1, header
	li a2, 14  # length to write
	ecall

get_size:
	la t0, header
	addi t1, t0, 2  # offset to size

	lhu t2, (t1)
	lhu t3, 2(t1)
	slli t3, t3, 16

	add t2, t2, t3
	mv s9, t2
	
	# print size
	li a7, 1
	mv a0, t2
	ecall
	
	# Print debug message
	li a7, 4
	la a0, newline
	ecall

get_offset:
	addi t1, t0, 10  # offset to offset

	lhu t2, (t1)
	lhu t3, 2(t1)
	slli t3, t3, 16

	add t2, t2, t3
	mv s8, t2

	# print offset
	li a7, 1
	mv a0, t2
	ecall
	
	# Print debug message
	li a7, 4
	la a0, newline
	ecall

get_rest_file:	
	# write header to write_only
	li a7, 64
	mv a0, s10  # file descriptor
	la a1, header
	li a2, 14  # length to write
	ecall
	
	# size and offset - header
	addi s9, s9, -14
	addi s8, s8, -14

	# Read rest from read_only
	li a7, 63
	mv a0, s11  # file descriptor
	la a1, header
	mv a2, s8  # length to read, from header to pixels
	ecall

	# write rest to write_only
	li a7, 64
	mv a0, s10  # file descriptor
	la a1, header
	mv a2, s8  # length to write
	ecall

get_width:
	la t0, header
	addi t1, t0, 4  # offset to width

	lw t2, (t1)

	# print width
	li a7, 1
	mv a0, t2
	ecall

	mv s7, t2  # save

	# Print debug message
	li a7, 4
	la a0, newline
	ecall

get_height:
	la t0, header
	addi t1, t0, 8  # offset to height

	lw t2, (t1)

	# print height
	li a7, 1
	mv a0, t2
	ecall

	mv s6, t2  # save

	# Print debug message
	li a7, 4
	la a0, newline
	ecall


allocate_heap:  # first byte (LSB) blue, then red, then green

	mul s0, s7, s6  # pixel amount (loop)
	slli s1, s0, 2

	addi t0, s8, 14  # full offset from start

	# move to pixels
	li a7, 62
	mv a0, s11  # file discreptor of read
	mv a1, t0
	li a2, 0
	ecall

	# allocate heap memory
	li a7, 9
	mv a0, s1
	ecall

	mv s4, a0  # save address of pixels

	# move to pixels
	li a7, 62
	mv a0, s11  # file discreptor of read
	mv a1, t0
	li a2, 0
	ecall

	# allocate heap memory
	li a7, 9
	mv a0, s1
	ecall

	mv s3, a0  # save address of copy of pixels

	# read copy of pixels
	li a7, 63
	mv a0, s11
	mv a1, s3  # address of heap
	mv a2, s1
	ecall

	# print pixel amount
	li a7, 1
	mv a0, s0
	ecall
	# Print debug message
	li a7, 4
	la a0, newline
	ecall

################################################################################################

colors:
	#li t2, 0  # black
	li t2, 0xFF000000
	#li t3, 255  # white
	li t3, 0xFFFFFFFF

first_two_rows:
	add t1, t0, s8  # move to start
	add s1, s7, s7  # loop counter

loop_first_two:
	addi s1, s1, -1

	# white or black
	lbu t4, 1(s3)
	addi t4, t4, -128
	blez t4, black_first_two

white_first_two:
	#sb t3, (s4)
	#sb t3, 1(s4)
	#sb t3, 2(s4)
	sw t3, (s4)
	j loop_first_two_end

black_first_two:
	sw t2, (s4)

loop_first_two_end:	
	addi s3, s3, 4
	addi s4, s4, 4
	bnez s1, loop_first_two

################################################################################################

middle_rows:

skip_two_rows:
	# loop counter
	sub s1, s0, s7  # s0 liczba pixeli
	sub s1, s1, s7
	sub s1, s1, s7
	sub s1, s1, s7

	# width in bytes
	slli s5, s7, 2

loop:
	addi s1, s1, -1

	li s2, 0

add_square:
	li t4, 0

	# right
	addi t4, s3, 4
	lbu t5, 2(t4)
	add s2, s2, t5

	# left
	addi t4, s3, -4
	lbu t5, 2(t4)
	add s2, s2, t5

	# up
	add t4, s3, s5
	lbu t5, 2(t4)
	add s2, s2, t5

	# down
	sub t4, s3, s5
	lbu t5, 2(t4)
	add s2, s2, t5

	# up right
	add t4, s3, s5
	addi t4, t4, 4
	lbu t5, 2(t4)
	add s2, s2, t5

	# down right
	sub t4, s3, s5
	addi t4, t4, 4
	lbu t5, 2(t4)
	add s2, s2, t5

	# up left
	add t4, s3, s5
	addi t4, t4, -4
	lbu t5, 2(t4)
	add s2, s2, t5

	# down left
	sub t4, s3, s5
	addi t4, t4, -4
	lbu t5, 2(t4)
	add s2, s2, t5

change_pixel:
	srli s2, s2, 3  # get medium

	# white or black
	lbu t4, 1(s3)
	sub t4, t4, s2
	addi t4, t4, 10
	blez t4, black

white:
	sw t3, (s4)
	j loop_end

black:
	sw t2, (s4)

loop_end:	
	addi s4, s4, 4
	addi s3, s3, 4
	bnez s1, loop

################################################################################################

last_two_rows:
	add s1, s7, s7  # loop counter

loop_last_two:
	addi s1, s1, -1
	
	# white or black
	lbu t4, 1(s3)
	addi t4, t4, -128
	blez t4, black_last_two

white_last_two:
	sw t3, (s4)
	j loop_last_two_end

black_last_two:
	sw t2, (s4)

loop_last_two_end:	
	addi s4, s4, 4
	bnez s1, loop_last_two

################################################################################################

end:
	slli s1, s0, 2
	sub s4, s4, s1  # return pointer to start of heap
	
	# write rest to write_only
	li a7, 64
	mv a0, s10
	mv a1, s4
	mv a2, s1 # write pixels
	ecall

	# Close file
	li a7, 57    
	mv a0, s11
	ecall

	# Close file
	li a7, 57    
	mv a0, s10
	ecall

	# Exit
	li a7, 10
	ecall
