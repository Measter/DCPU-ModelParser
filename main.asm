; --------------------------------------------
; Title:   Model Test
; Author:  Measter
; Date:    04/11/2012
; Version: 1.0
; --------------------------------------------

set pc, start

.include memory.asm
.include find_device.asm
.include model_parse.asm

:start
	set push, 0x1000
	jsr mem_init
	add sp, 1
	
	;Request memory for hardware pointer storage.
	;As this is the first allocation, it will be the same as [mem_start]
	;so we have no need to find the address.
	set push, 1
	jsr mem_request
	add sp, 1
	
	;Storing start of memory in I so we can access storage.
	set i, [mem_start]
		
	;Find the SPED port.
	set push, 0x42ba
	set push, 0xbf3c
	jsr find_device
	set [i], pop
	add sp, 1
	
	ife [i], 0xFFFF			;Device not found.
		set pc, end
	
	;Request space for VRAM from memory.
	;VRAM size = (IndexCount*2)/[mem_cluster_size] rounded up
	set a, [model_indices]
	mul a, 2
	div a, [mem_cluster_size]
	add a, 1					;Should result in rounding up.
	;A = required VRAM size.
	set push, a
	jsr mem_request
	set [i+1], pop				;Store cluster ID in storage area.
	
	;Fetch memory address by cluster ID
	set push, [i+1]
	jsr mem_get_address
	;No need to pop the address, as we need it where it is for parsing.
	
	;Parse model data
	;Destination is already on stack
	set push, model_indices
	set push, model_coords
	jsr model_parse
	add sp, 2					;Leave the destination on the stack.
	
	;Interface with SPED
	set a, 1					;Set to mapping mode.
	set x, pop					;Pop the destination to X.
	set y, [model_indices]		;First value at model_indices is the number of calculated vertices.
	hwi [i]						;First value at I is the SPED port.
	
	
	set x, 0					;Prepare for rotation.
:rotate
	set a, 2
	add x, 10
	hwi [i]
	set a, 0
	
:wait
	hwi [i]
	ife b, 1
		set pc, rotate
	set pc, wait

:end
	set pc, end
	
:model_coords
	;X, Y, Z
	;Front Lower
	dat 128, 108,  23	    ;Vertex 0
	dat 223, 108, 128		;Vertex 1
	dat 167, 108, 189		;Vertex 2
	dat 128, 108, 146		;Vertex 3
	dat 160, 108, 110		;Vertex 4
	dat 105, 108,  49		;Vertex 5
	;Front Upper
	dat  89, 108,  67		;Vertex 6
	dat 128, 108, 110		;Vertex 7
	dat  96, 108, 146		;Vertex 8
	dat 151, 108, 207		;Vertex 9
	dat 128, 108, 233		;Vertex 10
	dat  33, 108, 128		;Vertex 11
	
	;Rear Lower
	dat 128, 138,  23	    ;Vertex 12
	dat 223, 138, 128		;Vertex 13
	dat 167, 138, 189		;Vertex 14
	dat 128, 138, 146		;Vertex 15
	dat 160, 138, 110		;Vertex 16
	dat 105, 138,  49		;Vertex 17
	;Rear Upper
	dat  89, 138,  67		;Vertex 18
	dat 128, 138, 110		;Vertex 19
	dat  96, 138, 146		;Vertex 20
	dat 151, 138, 207		;Vertex 21
	dat 128, 138, 233		;Vertex 22
	dat  33, 138, 128		;Vertex 23

;The order that the vertices will be drawn.
:model_indices
	;Index count.
	dat 36
	;Vertex, Color, Intesity
	;Front Lower
	dat  5, 2, 1
	dat  0, 2, 1
	dat  1, 2, 1
	dat  2, 2, 1
	dat  3, 2, 1
	dat  4, 2, 1
	dat  5, 2, 1			;Next index connects to Front Upper
	dat  5, 0, 0			;Ensures the connecting line is black
	
	;8 indices at this point.
	
	;Front Upper
	dat  6, 0, 0			;Ensures the connection to the next line is coloured.
	dat  6, 2, 1
	dat  7, 2, 1
	dat  8, 2, 1
	dat  9, 2, 1
	dat 10, 2, 1
	dat 11, 2, 1
	dat  6, 2, 1			;Ensures connector line is coloured. Next connector is Rear Upper.
	dat  6, 0, 0
	
	;17 indices.
	
	;Rear Upper
	dat 18, 0, 0
	dat 18, 2, 1
	dat 19, 2, 1
	dat 20, 2, 1
	dat 21, 2, 1
	dat 22, 2, 1
	dat 23, 2, 1
	dat 18, 2, 1
	dat 18, 0, 0			;Ensure black connector.
	
	;26 indices.
	
	;Rear Lower
	dat 17, 0, 0			;Ensures connector line is black.
	dat 17, 2, 1
	dat 12, 2, 1
	dat 13, 2, 1
	dat 14, 2, 1
	dat 15, 2, 1
	dat 16, 2, 1
	dat 17, 2, 1
	dat 17, 0, 0			;Ensure connector is black.
	dat  5, 0, 0			;Return to start.
	
	;36 indices.

.include memory_end.asm