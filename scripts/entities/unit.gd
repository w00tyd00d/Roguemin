class_name Unit extends Entity

## The entity the [Player] controls to do tasks for them.

## The id # of the unit to identify which instance it is.
var id: int

## The current type of the unit.
var type: Type.Unit

## Returns if the unit has been upgraded or not.
var upgraded: bool

## The current state of the unit.
var state: State:
	get:
		return brain.state

## The boid data of the unit.
var boid: Boid

## The current target of the unit.
var target

## The cached location which the unit last saw the player from, mainly used
## as a means for hauling MTEs in the void where there is no flow field to
## navigate.
var last_player_tile: Tile

## The object the unit is currently holding on to.
var held_object: MultiTileEntity

## The enemy the unit is current on top of, if at all.
var riding_enemy: Enemy

## A cached path to the unit's target.
var path: Array:
	set(arr):
		path = arr
		if not path.is_empty():
			GameState.ASTAR_TEST.emit(arr)

## The location of the next point along the unit's path
var next_destination: Vector2i:
	get:
		if not path.is_empty():
			return path[0]
		if target:
			return target.grid_position

		return Vector2i()

## A flag representing if the unit is is_idle.
var is_idle: bool:
	# get: return state == State.IDLE
	get:
		return brain.state_is(States.Unit.IDLE)

var is_dead: bool:
	get:
		return brain.state_is(States.Unit.DEAD)

## A flag representing if the unit is in limbo (ie: not in the field).
var in_limbo: bool:
	get:
		return grid_position == Vector2i()

## A flag for whether not the unit is allowed to stack with other units
var can_stack: bool:
	get:
		return brain.state_is(States.Unit.ATTACK)

# DEBUG
@onready var sightline_boid := $Sightline1 as ColorRect
@onready var sightline_centroid := $Sightline2 as ColorRect
#


func _init() -> void:
	brain = UnitBrain.new(self)
	boid = Boid.new(self)


func _ready() -> void:
	add_to_group(&"units")
	super()


static func metadata(_type: Type.Unit) -> Dictionary:
	match _type:
		Type.Unit.RED:
			return {name = "Red", color = Color.RED}
		Type.Unit.YELLOW:
			return {name = "Yellow", color = Color.YELLOW}
		Type.Unit.BLUE:
			return {name = "Blue", color = Color.BLUE}
		Type.Unit.NONE:
			return {name = "None", color = Color.DARK_GRAY}
	return {}


func get_metadata() -> Dictionary:
	return Unit.metadata(type)


func reset() -> void:
	hide()

	modulate.a = 1
	set_background(Vector2(), Glyphs.BLACK)

	if not brain.state_is(States.Unit.DEAD):  #and world:
		brain.change_state(States.Unit.DEAD)

	grid_position = Vector2()
	last_player_tile = null
	boid.reset()

	process_mode = Node.PROCESS_MODE_DISABLED


func spawn(pos: Vector2i, _type: Type.Unit, _upgraded := false) -> void:
	type = _type
	upgraded = true  # No time to implement nectar :(
	grid_position = pos

	var new_state = States.Unit.FOLLOW if _in_range_of_tether() else States.Unit.IDLE
	brain.change_state(new_state)

	show()


func upgrade() -> void:
	if upgraded:
		return
	upgraded = true
	_update_glyph(is_idle)


func die() -> void:
	brain.change_state(States.Unit.DEAD)

	set_glyph(Vector2(), Glyphs.UNIT_GHOST_LARGE)
	set_background(Vector2(), Glyphs.NONE)
	z_index += 1

	var end_pos := position + Vector2(Direction.north.vector * Globals.TILE_SIZE * 2)

	process_mode = Node.PROCESS_MODE_ALWAYS

	var tween := create_tween()
	tween.tween_property(self, "position", end_pos, 1.5)
	tween.parallel().tween_property(self, "modulate:a", 0, 1.25)
	tween.tween_callback(
		func():
			z_index -= 1
			reset()
	)


func move_to(dest: Tile) -> void:
	# DEBUG
	if current_tile.type != Type.Tile.VOID and dest.type == Type.Tile.WALL:
		pass

	world.move_unit(self, dest)


func swap_with(dest: Tile) -> bool:
	var units := dest.get_all_units()

	if units.size() > 1 or last_position == grid_position:  # Can't swap with multiple units  # Prevent oscillation
		return false

	# Do a centroid distance check
	var dist1 := boid.centroid.position.distance_to(grid_position)
	var dist2 := boid.centroid.position.distance_to(dest.grid_position)

	if dist1 <= dist2:
		return false

	var nbr := units[0]

	# Prevent swapping with units of the same type
	# MAY NEED TO CHANGE FOR ATTACKING PURPOSES
	if nbr.type == type:
		return false

	if nbr.boid.centroid and nbr.boid.centroid.count > 1:
		# Check distance from current position to neighbors centroid to see
		# what their new distance would be if they swapped
		var ndist := grid_position.distance_to(nbr.boid.centroid.position)

		if ndist > dist2:
			return false

	nbr.move_to(current_tile)
	move_to(dest)

	return true


func move_towards(dest: Tile) -> bool:
	if name == "Unit74":
		pass

	var boid_tile := boid.get_next_tile(dest)
	if boid_tile.grid_position == grid_position:
		return false

	var dir := Direction.by_delta(grid_position, boid_tile.grid_position)
	if not dir or dir == Direction.none:
		return false

	if _check_move([dir]):
		return true

	var dist := grid_position.distance_to(target.grid_position)
	if dist < Globals.UNIT_DISTANCE_CLOSE:
		return false

	if _check_move(dir.adjacent):
		return true

	var cheby := Util.chebyshev(grid_position, target.grid_position)
	if cheby <= Globals.UNIT_DISTANCE_MEDIUM and _can_see_position(dest.grid_position):
		return false

	if _check_move(dir.orthogonal):
		return true

	if _can_see_position(dest.grid_position):
		return false

	return _check_move(dir.oppadjacent)


func throw_to(tile: Tile) -> void:
	last_player_tile = player.current_tile

	if tile.has_entities:
		var ent := tile.get_first_entity()

		if ent:
			match ent.type:
				Type.Entity.TREASURE:
					target = ent
					brain.change_state(States.Unit.CARRY)
					var latch := ent.get_open_latch_tile()
					if latch:
						move_to(latch)
						grab_object(ent)
						return

				Type.Entity.ENEMY:
					pass

		tile = world.get_closest_empty_tile(tile)

	move_to(tile)
	go_idle()


func join_squad() -> void:
	last_player_tile = null
	brain.change_state(States.Unit.FOLLOW)
	player.add_unit(self)


func dismiss() -> void:
	last_player_tile = player.current_tile
	go_idle()


func ride_enemy(enemy: Enemy) -> void:
	if riding_enemy:
		return
	enemy.add_unit(self)
	riding_enemy = enemy


func get_off_enemy() -> void:
	if not riding_enemy:
		return
	riding_enemy.remove_unit(self)

	move_to(world.get_closest_empty_tile(riding_enemy.current_tile))
	riding_enemy = null


func grab_object(obj: MultiTileEntity) -> bool:
	if obj.add_carrier(self):
		held_object = obj
		return true

	return false


func drop_object() -> void:
	if not held_object:
		return
	held_object.remove_carrier(self)
	held_object = null


func go_home() -> void:
	brain.change_state(States.Unit.RETURN)


func go_idle() -> void:
	brain.change_state(States.Unit.IDLE)


func _do_move_action(dest: Tile) -> bool:
	# DEBUG
	# if world.query_tile(dest) == Type.Tile.WALL:
	#     pass

	if dest.has_units and not can_stack:
		return swap_with(dest)

	move_to(dest)
	return true


func _check_move(options: Array[Direction]) -> bool:
	for dir in options:
		var res := _check_tile_at(grid_position + dir.vector)
		var next_tile := world.get_tile(grid_position + dir.vector)

		if res == Type.Tile.UNIT and next_tile.type == Type.Tile.WALL:
			pass

		match res:
			Type.Tile.WALL:
				if brain.state_is(States.Unit.RETURN) and Tag.has(next_tile, Tags.UNIT_SHIP):
					reset()
					return true  # We reset, so no action cost needed
				
				if current_tile.type == Type.Tile.VOID:
					return _do_move_action(next_tile)

			Type.Tile.ENTITY:
				continue

			_:
				if _do_move_action(next_tile):
					return true

	return false


func _in_range_of_tether() -> bool:
	var dest := player.unit_tether.tail.grid_position
	var dist := Util.chebyshev(grid_position, dest)

	return dist <= Globals.UNIT_SIGHT_RANGE


func _can_see_position(dest_pos: Vector2i) -> bool:
	var raycast := DDARC.to_grid_position(
		grid_position,
		dest_pos,
		func(ctx: DDARC.Context):
			var pos := ctx.grid_position
			var query := world.query_tile_at(pos)
			if (
				not world.in_bounds(pos)
				or query == Type.Tile.ENTITY
				or query == Type.Tile.WALL and not current_tile.type == Type.Tile.VOID
			):
				return true
	)

	return raycast.grid_position == dest_pos


func _can_see_tether() -> bool:
	var tail := player.unit_tether.tail
	return _can_see_position(tail.grid_position)


func _check_tile_at(pos: Vector2i) -> Type.Tile:
	var tile := world.get_tile(pos)
	var res := world.query_tile(tile)

	# Cascade forward to see if we can resolve movement
	if res == Type.Tile.UNIT:
		# DEBUG
		if tile.type == Type.Tile.WALL:
			pass

		var old_position := grid_position
		var any := false

		for unit in tile.get_all_units():
			if unit.time < world.time and unit.update():
				any = true
		if any:
			var delta := grid_position - old_position
			var new_pos := pos + delta
			return _check_tile_at(new_pos)

	# DEBUG
	if res == Type.Tile.UNIT and tile.type == Type.Tile.WALL:
		pass

	return res


func _broadcast_path() -> void:
	if path.is_empty():
		return

	Util.foreach_around_pos(
		grid_position,
		5,
		func(pos: Vector2i, _data: Dictionary):
			var tile := world.get_tile(pos)

			if not tile:
				return

			for unit in tile.get_all_units():
				var empty_path := unit.path.is_empty()
				if unit.target == target and (empty_path or unit.path[0] != path[0]):
					unit._receive_path(path)
	)


func _receive_path(_path: Array[Vector2i]) -> void:
	_path = _path.duplicate()
	while not _path.is_empty():
		var dist1 := Util.chebyshev(_path[0], _path[-1])
		var dist2 := Util.chebyshev(grid_position, _path[-1])
		if dist1 < dist2:
			path = _path
			return
		_path.pop_front()


func _update_glyph(_idle := false) -> void:
	match type:
		Type.Unit.RED:
			if upgraded:
				if _idle:
					set_glyph(Vector2(), Glyphs.UNIT_RED_LARGE_IDLE)
				else:
					set_glyph(Vector2(), Glyphs.UNIT_RED_LARGE)
			elif _idle:
				set_glyph(Vector2(), Glyphs.UNIT_RED_SMALL_IDLE)
			else:
				set_glyph(Vector2(), Glyphs.UNIT_RED_SMALL)
		Type.Unit.YELLOW:
			if upgraded:
				if _idle:
					set_glyph(Vector2(), Glyphs.UNIT_YELLOW_LARGE_IDLE)
				else:
					set_glyph(Vector2(), Glyphs.UNIT_YELLOW_LARGE)
			elif _idle:
				set_glyph(Vector2(), Glyphs.UNIT_YELLOW_SMALL_IDLE)
			else:
				set_glyph(Vector2(), Glyphs.UNIT_YELLOW_SMALL)
		Type.Unit.BLUE:
			if upgraded:
				if _idle:
					set_glyph(Vector2(), Glyphs.UNIT_BLUE_LARGE_IDLE)
				else:
					set_glyph(Vector2(), Glyphs.UNIT_BLUE_LARGE)
			elif _idle:
				set_glyph(Vector2(), Glyphs.UNIT_BLUE_SMALL_IDLE)
			else:
				set_glyph(Vector2(), Glyphs.UNIT_BLUE_SMALL)
