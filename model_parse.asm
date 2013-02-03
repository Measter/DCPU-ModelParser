; --------------------------------------------
; Title:   Model Data Parse
; Author:  Measter
; Date:    04/11/2012
; Version: 1.0
; --------------------------------------------


; Struct - Vertex
; List of vertices in XYZ format.
; 0x0-2			: Vertex 0 coordinates.
; 0x3-5			: Vertex 1 coordinates.
; ...

; Struct - Index
; List of indices to use when drawing, in the order to draw.
; Also contains the colour and intensity value.
; 0x0			: Number of indices.
; 0x1-3			: Vertex 0 index, colour, intensity.

;Parses XYZ, and Indice/Color/Intensty structs.
;Input
; SP+2			: Memory address to store the parsed vertices.
; SP+1			: Memory address storing the index data.
; SP+0			: Memory address storing the vertex data.
:model_parse
	set push, z
	set z, sp
	add z, 2
	set push, i
	set push, a
	set push, b
	set push, c
	set push, x
	set push, j
	
	set a, [z+2]	
	;A = the address to write parsed data.
	set i, 0
	set b, [z+1]
	add b, 1				;skipping the index count.
	;B = index to read.
	set j, [z+1]
	set j, [j]
	;J = number of indices.
	
	;for each index...
	:model_parse_loop_start
		add i, 1
		
		set x, [b]
		mul x, 3
		;X = Memory offset of vertex.
		
		set c, [z]
		add c, x
		;C = vertex data address.
		
		;Mask Y coordinate.
		and [c+1], 0xFF
		
		;Fetch y coordinate, store it in [dest], and shift left by 8.
		set [a], [c+1]
		shl [a], 8
		
		;Mask X coordinate.
		and [c], 0xFF
		;Add x coordinate to [dest].
		BOR [a], [c]
	
		;Increment dest.
		add a, 1
	
		;Fetch intensity, and store it in [dest], and shift left by 2.
		and [b+2], 0x1		;Mask the first bit.
		set [a], [b+2]
		shl [a], 2
		;Add colour to [dest].
		and [b+1], 0x3		;Mask only the first two bits.
		bor [a], [b+1]
		shl [a], 8
		
		;Fetch z, and store in in [dest].
		and [c+2], 0xFF		;Mask the first 8 bits.
		bor [a], [c+2]
		
		;increment dest again for next loop
		add a, 1		
		;increment index address by 3 to go to next array.
		add b, 3
		
		ifn i, j				;[z+1] is the number of indices.
			set pc, model_parse_loop_start
	
	set j, pop
	set x, pop
	set c, pop
	set b, pop
	set a, pop
	set i, pop
	set z, pop
	set pc, pop