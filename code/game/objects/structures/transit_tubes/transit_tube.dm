
/obj/structure/transit_tube
	name = "transit tube"
	icon = 'icons/obj/pipes_n_cables/transit_tube.dmi'
	icon_state = "straight"
	desc = "A transit tube for moving things around."
	density = TRUE
	layer = LOW_ITEM_LAYER
	anchored = TRUE
	pass_flags_self = PASSGLASS
	var/tube_construction = /obj/structure/c_transit_tube
	var/list/tube_dirs //list of directions this tube section can connect to.
	var/exit_delay = 1
	var/enter_delay = 0

/obj/structure/transit_tube/Initialize(mapload, newdirection)
	. = ..()
	if(newdirection)
		setDir(newdirection)
	init_tube_dirs()
	update_appearance()
	AddElement(/datum/element/climbable)
	AddElement(/datum/element/elevation, pixel_shift = 12)

/obj/structure/transit_tube/Destroy()
	for(var/obj/structure/transit_tube_pod/P in loc)
		P.deconstruct(FALSE)
	return ..()

/obj/structure/transit_tube/singularity_pull(atom/singularity, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct(FALSE)

/obj/structure/transit_tube/attackby(obj/item/W, mob/user, list/modifiers, list/attack_modifiers)
	if(W.tool_behaviour == TOOL_WRENCH)
		if(tube_construction)
			for(var/obj/structure/transit_tube_pod/pod in src.loc)
				to_chat(user, span_warning("Remove the pod first!"))
				return
			user.visible_message(span_notice("[user] starts to detach \the [src]."), span_notice("You start to detach \the [src]..."))
			if(W.use_tool(src, user, 2 SECONDS, volume=50))
				to_chat(user, span_notice("You detach \the [src]."))
				var/obj/structure/c_transit_tube/R = new tube_construction(loc)
				R.setDir(dir)
				transfer_fingerprints_to(R)
				R.add_fingerprint(user)
				qdel(src)
	else if(W.tool_behaviour == TOOL_CROWBAR)
		for(var/obj/structure/transit_tube_pod/pod in src.loc)
			pod.attackby(W, user)
	else
		return ..()

// Called to check if a pod should stop upon entering this tube.
/obj/structure/transit_tube/proc/should_stop_pod(pod, from_dir)
	return FALSE

// Called when a pod stops in this tube section.
/obj/structure/transit_tube/proc/pod_stopped(pod, from_dir)
	return


/obj/structure/transit_tube/proc/has_entrance(from_dir)
	from_dir = REVERSE_DIR(from_dir)

	for(var/direction in tube_dirs)
		if(direction == from_dir)
			return TRUE

	return FALSE



/obj/structure/transit_tube/proc/has_exit(in_dir)
	for(var/direction in tube_dirs)
		if(direction == in_dir)
			return TRUE

	return FALSE



// Searches for an exit direction within 45 degrees of the
//  specified dir. Returns that direction, or 0 if none match.
/obj/structure/transit_tube/proc/get_exit(in_dir)
	var/near_dir = 0
	var/in_dir_cw = turn(in_dir, -45)
	var/in_dir_ccw = turn(in_dir, 45)

	for(var/direction in tube_dirs)
		if(direction == in_dir)
			return direction

		else if(direction == in_dir_cw)
			near_dir = direction

		else if(direction == in_dir_ccw)
			near_dir = direction

	return near_dir


// Return how many BYOND ticks to wait before entering/exiting
//  the tube section. Default action is to return the value of
//  a var, which wouldn't need a proc, but it makes it possible
//  for later tube types to interact in more interesting ways
//  such as being very fast in one direction, but slow in others
/obj/structure/transit_tube/proc/exit_delay(pod, to_dir)
	return exit_delay

/obj/structure/transit_tube/proc/enter_delay(pod, to_dir)
	return enter_delay


/obj/structure/transit_tube/proc/init_tube_dirs()
	switch(dir)
		if(NORTH)
			tube_dirs = list(NORTH, SOUTH)
		if(SOUTH)
			tube_dirs = list(NORTH, SOUTH)
		if(EAST)
			tube_dirs = list(EAST, WEST)
		if(WEST)
			tube_dirs = list(EAST, WEST)

/obj/structure/transit_tube/update_overlays()
	. = ..()
	for(var/direction in tube_dirs)
		if(!ISDIAGONALDIR(direction))
			. += create_tube_overlay(direction)
			continue
		if(!(direction & NORTH))
			continue

		. += create_tube_overlay(direction ^ 3, NORTH)
		if(direction & EAST)
			. += create_tube_overlay(direction ^ 12, EAST)
		else
			. += create_tube_overlay(direction ^ 12, WEST)

/obj/structure/transit_tube/proc/create_tube_overlay(direction, shift_dir)
	// We use image() because a mutable appearance will have its dir mirror the parent which sort of fucks up what we're doing here
	var/image/tube_overlay = image(icon, dir = direction)
	if(shift_dir)
		tube_overlay.icon_state = "decorative_diag"
		switch(shift_dir)
			if(NORTH)
				tube_overlay.pixel_z = 32
			if(SOUTH)
				tube_overlay.pixel_z = -32
			if(EAST)
				tube_overlay.pixel_w = 32
			if(WEST)
				tube_overlay.pixel_w = -32
	else
		tube_overlay.icon_state = "decorative"

	tube_overlay.overlays += emissive_blocker(icon, tube_overlay.icon_state, src)
	return tube_overlay

//Some of these are mostly for mapping use
/obj/structure/transit_tube/horizontal
	dir = WEST


/obj/structure/transit_tube/diagonal
	icon_state = "diagonal"
	tube_construction = /obj/structure/c_transit_tube/diagonal

/obj/structure/transit_tube/diagonal/init_tube_dirs()
	switch(dir)
		if(NORTH)
			tube_dirs = list(NORTHEAST, SOUTHWEST)
		if(SOUTH)
			tube_dirs = list(NORTHEAST, SOUTHWEST)
		if(EAST)
			tube_dirs = list(NORTHWEST, SOUTHEAST)
		if(WEST)
			tube_dirs = list(NORTHWEST, SOUTHEAST)

//mostly for mapping use
/obj/structure/transit_tube/diagonal/topleft
	dir = WEST

/obj/structure/transit_tube/diagonal/crossing
	density = FALSE
	icon_state = "diagonal_crossing"
	tube_construction = /obj/structure/c_transit_tube/diagonal/crossing

//mostly for mapping use
/obj/structure/transit_tube/diagonal/crossing/topleft
	dir = WEST


/obj/structure/transit_tube/curved
	icon_state = "curved0"
	tube_construction = /obj/structure/c_transit_tube/curved

/obj/structure/transit_tube/curved/init_tube_dirs()
	switch(dir)
		if(NORTH)
			tube_dirs = list(NORTH, SOUTHWEST)
		if(SOUTH)
			tube_dirs = list(SOUTH, NORTHEAST)
		if(EAST)
			tube_dirs = list(EAST, NORTHWEST)
		if(WEST)
			tube_dirs = list(SOUTHEAST, WEST)

/obj/structure/transit_tube/curved/flipped
	icon_state = "curved1"
	tube_construction = /obj/structure/c_transit_tube/curved/flipped

/obj/structure/transit_tube/curved/flipped/init_tube_dirs()
	switch(dir)
		if(NORTH)
			tube_dirs = list(NORTH, SOUTHEAST)
		if(SOUTH)
			tube_dirs = list(SOUTH, NORTHWEST)
		if(EAST)
			tube_dirs = list(EAST, SOUTHWEST)
		if(WEST)
			tube_dirs = list(NORTHEAST, WEST)


/obj/structure/transit_tube/junction
	icon_state = "junction0"
	tube_construction = /obj/structure/c_transit_tube/junction

/obj/structure/transit_tube/junction/init_tube_dirs()
	switch(dir)
		if(NORTH)
			tube_dirs = list(NORTH, SOUTHEAST, SOUTHWEST)//ending with the prefered direction
		if(SOUTH)
			tube_dirs = list(SOUTH, NORTHWEST, NORTHEAST)
		if(EAST)
			tube_dirs = list(EAST, SOUTHWEST, NORTHWEST)
		if(WEST)
			tube_dirs = list(WEST, NORTHEAST, SOUTHEAST)

/obj/structure/transit_tube/junction/flipped
	icon_state = "junction1"
	tube_construction = /obj/structure/c_transit_tube/junction/flipped

/obj/structure/transit_tube/junction/flipped/init_tube_dirs()
	switch(dir)
		if(NORTH)
			tube_dirs = list(NORTH, SOUTHWEST, SOUTHEAST)//ending with the prefered direction
		if(SOUTH)
			tube_dirs = list(SOUTH, NORTHEAST, NORTHWEST)
		if(EAST)
			tube_dirs = list(EAST, NORTHWEST, SOUTHWEST)
		if(WEST)
			tube_dirs = list(WEST, SOUTHEAST, NORTHEAST)


/obj/structure/transit_tube/crossing
	icon_state = "crossing"
	tube_construction = /obj/structure/c_transit_tube/crossing
	density = FALSE

//mostly for mapping use
/obj/structure/transit_tube/crossing/horizontal
	dir = WEST
