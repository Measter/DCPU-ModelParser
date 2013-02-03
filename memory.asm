; --------------------------------------------
; Title:   MemFunctions
; Author:  Measter
; Date:    02/11/2012
; Version: 1.0a
; --------------------------------------------

; Creates memory tree. Tree stores whether cluster is in use, and size
; of allocation.
; sp+0		: Stack Reserved Space
:mem_init
	set push, z
	set z, sp
	add z, 2
	set push, a
	set push, i
	
	ife [mem_is_init], 1
		set pc, mem_init_skip
	
	set i, 0
	:mem_init_size_calc
		;Find size of available memory.
		;A = length of memory.
		set a, 0xFFFF
		sub a, mem_tree
		sub a, [z]				;Space for stack.
		sub a, [mem_tree_size]	;Take into account the current size of the tree.
	
		;Set tree size.
		set [mem_tree_size], a
		div [mem_tree_size], [mem_cluster_size]
		
		add i, 1
		ifn i, 3
			set pc, mem_init_size_calc
	
	;Set mem_start to end of tree.
	set [mem_start], mem_tree
	add [mem_start], [mem_tree_size]
	
	;Set init check to true.
	set [mem_is_init], 1
	
	:mem_init_skip
	
	set i, pop
	set a, pop
	set z, pop
	set pc, pop
	
; Frees a section of clusters.
; Input
; SP+1		: Zero Cluster Memory
;			: 1 = Yes
;			: 0 - No
; SP+0		: Cluster ID
:mem_free
	set push, z
	set z, sp
	add z, 2
	set push, a
	set push, b
	set push, c
	
	;Find first cluster in tree.
	;A = start cluster ID.
	set a, mem_tree
	add a, [z]
	
	;Find number of clusters in allocation.
	;C = cluster count
	set c, [a]
	;C = last cluster ID.
	add c, a	
	
	;Zero cluster memory if requested
	ife [z+1], 0
		set pc, mem_free_skip_zero
	
	set push, 0			;Value.
	set push, [z]		;Cluster ID
	jsr mem_fill
	add sp, 2
	
	:mem_free_skip_zero
	
	;Iterate over allocation tree, starting from giver cluster ID,
	;untill we reach end of allocation. Set value of all to 0 as we go.
	:mem_free_loop_start
		ife a, c
			set pc, mem_free_loop_end
		
		set [a], 0
		add a, 1
		set pc, mem_free_loop_start
	:mem_free_loop_end
	
	set c, pop
	set b, pop
	set a, pop
	set z, pop
	set pc, pop

; Requests a memory allocation.
; Input
; SP+0		: Cluster Count
; Output
; SP+0		: Cluster ID if found space.
;			: 0xFFFF if no space found.
:mem_request
	set push, z
	set z, sp
	add z, 2
	set push, a
	set push, i
	set push, b
	set push, c
	
	ife [z], 0
		set pc, mem_request_exit
	
	;Check if memory has been initialized.
	ife [mem_is_init], 0
		set pc, mem_request_init
	set pc, mem_request_no_init

	;Initialize memory, with 0x1000 word stack reserve.
	:mem_request_init
		set push, 0x1000
		jsr mem_init
		add sp, 1

	:mem_request_no_init
	
	;A = Current location.
	set a, mem_tree
		
	;Iterate over tree, find space big enough for request.
	:mem_request_loop_start
		ife a, [mem_start]		;End of tree reached.
			set pc, mem_request_exit_loop_null
			
		;Starting at A, go over the following N clusters to see if
		;they are available. Where N = cluster count.
		;I = loop counter.
		;B = cluster being checked for use.
		;C = whether requested size can fit in section.
		set i, 0
		set b, a 	;Set B to A for inner check.
		set c, 1	;Whether we can fit the request in available area.
		
		:mem_request_inner_check_loop_start
			ife i, [z]
				set pc, mem_request_inner_check_loop_exit
			
			;if the value of B is not 0, then it has already been allocated.
			ifn [b], 0
				set pc, mem_request_in_use
			set pc, mem_request_not_in_use
			
			:mem_request_in_use
				set c, 0
				set a, b    ;Set A to the start of the found allocation.
				add a, [b]	;Add the value of B to skip to the end
							;of the allocation.
				;A = the cluster ID after the end of the found allocation.
				set pc, mem_request_inner_check_loop_exit
			
			:mem_request_not_in_use
			add i, 1
			add b, 1
			set pc, mem_request_inner_check_loop_start
		
		:mem_request_inner_check_loop_exit
		
		;If a suitable area has been found (if C = 1),
		;set all sectors from A to B as used.
		ife c, 0
			set pc, mem_request_skip_set
		
		sub b, 1				;Fix fencepost error.
		:mem_request_set_loop_start
			set [b], [z]			;Store cluster size in tree	
			ife b, a
				set pc, mem_request_exit_loop_found 
			sub b, 1
			set pc, mem_request_set_loop_start
		
		:mem_request_set_loop_exit
			
		:mem_request_skip_set
		
		set pc, mem_request_loop_start
	
	:mem_request_exit_loop_found
		;A = memory cluster ID.
		sub a, mem_tree
		set [z], a			;Stick it in the stack for retrieval.
		set pc, mem_request_exit
	
	:mem_request_exit_loop_null
		set [z], 0xFFFF
	
	:mem_request_exit
	set c, pop
	set b, pop
	set i, pop
	set a, pop
	set z, pop
	set pc, pop

; Fills the given cluster ID with the given value
; sp+1		: Fill Value
; sp+0		: Cluster ID (0-indexed)
:mem_fill
	set push, z			
	set z, sp			
	add z, 2			
	set push, i			
	set push, a			
	set push, b
	
	;Get cluster size.
	set b, mem_tree
	add b, [z]
	;B = allocated size.
	set b, [b]
	
	;Cluster start location = (id * size) + mem_start.
	;I = start location.
	set i, [z]
	mul i, [mem_cluster_size]
	add i, [mem_start]
		
	;Size = count * cluster size.
	set a, b
	mul a, [mem_cluster_size]
	
	;Set end point.
	;A = end location,
	add a, i
	
	;For each word in the cluster location
	;  set word to new value.
	:mem_fill_loop_start
		ife i, a	
			set pc, mem_fill_loop_end
		
		set [i], [z+1]		;Set value.
		add i, 1
		set pc, mem_fill_loop_start
	:mem_fill_loop_end
	
	set b, pop
	set a, pop			
	set i, pop			
	set z, pop			
	set pc, pop
	
; Fetches the memory address of the given cluster ID
; Input
; SP+0		: Cluster ID.
; Output
; SP+0		: Memory Address.
:mem_get_address
	set push, z
	set z, sp
	add z, 2
	
	;Cluster start location = (id * size) + mem_start.
	mul [z], [mem_cluster_size]
	add [z], [mem_start]
	
	set z, pop
	set pc, pop