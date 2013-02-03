; --------------------------------------------
; Title:   MemMarkers
; Author:  Measter
; Date:    02/11/2012
; Version: 1.0
; --------------------------------------------

;Setting the words per cluster. The larger the cluster is, the smaller the
;allocation tree will be.
:mem_cluster_size
	dat 0x20
;Stores the memory initialization state.
:mem_is_init
	dat 0
;Stores the start location of the memory clusters.
:mem_start
	dat 0
;This is the size of the allocation tree.
:mem_tree_size
	dat 0
;The start of the allocation tree and memory.
;This must be at the end of the program.
:mem_tree