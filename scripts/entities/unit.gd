class_name Unit extends Entity

## The entity the [Player] controls to do tasks for them.

## The current type of the unit.
var type : Type.Unit

## Returns if the unit has been upgraded or not.
var upgraded : bool

## The current state of the unit.
var state : State :
    get: return brain.state

## The boid data of the unit.
var boid : Boid

## The current target of the unit.
var target

## The cached location which the unit last saw the player from, mainly used
## as a means for hauling MTEs in the void where there is no flow field to
## navigate.
var last_player_tile : Tile

## The object the unit is currently holding on to.
var held_object : MultiTileEntity

## The enemy the unit is current on top of, if at all.
var riding_enemy : Enemy

## A cached path to the unit's target.
var path : Array :
    set(arr):
        path = arr
        if not path.is_empty():
            GameState.ASTAR_TEST.emit(arr)

## The location of the next point along the unit's path
var next_destination : Vector2i :
    get:
        if not path.is_empty():
            return path[0]
        elif target:
            return target.grid_position

        return Vector2i()

## A flag representing if the unit is is_idle.
var is_idle : bool :
    # get: return state == State.IDLE
    get: return brain.state_is(States.Unit.IDLE)

var is_dead : bool :
    get: return brain.state_is(States.Unit.DEAD)

## A flag representing if the unit is in limbo (ie: not in the field).
var in_limbo : bool :
    get: return grid_position == Vector2i()

## A flag for whether not the unit is allowed to stack with other units
var can_stack : bool :
    get: return brain.state_is(States.Unit.ATTACK)


# DEBUG
@onready var sightline_boid := $Sightline1 as ColorRect
@onready var sightline_centroid := $Sightline2 as ColorRect
#


func _init() -> void:
    brain = UnitBrain.new(self)
    boid = Boid.new(self)


func _ready() -> void:
    add_to_group(&"units")


static func metadata(_type: Type.Unit) -> Dictionary:
    match _type:
        Type.Unit.RED: return { name = "Red", color = Color.RED }
        Type.Unit.YELLOW: return { name = "Yellow", color = Color.YELLOW }
        Type.Unit.BLUE: return { name = "Blue", color = Color.BLUE }
        Type.Unit.NONE: return { name = "None", color = Color.DARK_GRAY }
    return {}


func get_metadata() -> Dictionary:
    return Unit.metadata(type)


func reset() -> void:
    hide()

    modulate.a = 1
    set_background(Vector2(), Glyph.BLACK)

    if not brain.state_is(States.Unit.DEAD): #and world:
        brain.change_state(States.Unit.DEAD)

    grid_position = Vector2()
    last_player_tile = null
    boid.reset()
    


func spawn(pos: Vector2i, _type: Type.Unit, _upgraded := false) -> void:
    type = _type
    upgraded = true # No time to implement nectar :(
    grid_position = pos
    
    var _state = States.Unit.FOLLOW if _in_range_of_tether() else States.Unit.IDLE
    brain.change_state(_state)
    
    show()


func upgrade() -> void:
    if upgraded: return
    upgraded = true
    _update_glyph(is_idle)


func die() -> void:
    brain.change_state(States.Unit.DEAD)

    set_glyph(Vector2(), Glyph.UNIT_GHOST_LARGE)
    set_background(Vector2(), Glyph.NONE)
    z_index += 1

    var end_pos := position + Vector2(Direction.north.vector * Globals.TILE_SIZE * 2)

    var tween := create_tween()
    tween.tween_property(self, "position", end_pos, 1.5)
    tween.parallel().tween_property(self, "modulate:a", 0, 1.25)
    tween.tween_callback(func():
        z_index -= 1
        reset()
    )


func move_to(dest: Tile) -> void:
    world.move_unit(self, dest)


func swap_with(dest: Tile) -> bool:
    var units := dest.get_all_units()

    if (units.size() > 1 or                 # Can't swap with multiple units
        last_position == grid_position):    # Prevent oscillation
            return false

    # Do a centroid distance check
    #var dist1 := Util.chebyshev_distance(centroid.position, grid_position)
    #var dist2 := Util.chebyshev_distance(centroid.position, dest.grid_position)

    var dist1 := boid.centroid.position.distance_to(grid_position)
    var dist2 := boid.centroid.position.distance_to(dest.grid_position)

    # NOT CHECKING DISTANCE OF OTHER UNIT'S CENTROID MIGHT CAUSE OSCILLATION
    # LEAVING IT SIMPLE FOR NOW
    if dist1 <= dist2:
        return false

    var nbr := units[0]

    # MAY NEED TO CHANGE FOR ATTACKING PURPOSES
    if nbr.type == type:
        return false

    if nbr.boid.centroid and nbr.boid.centroid.count > 1:
        #var ndist1 := Util.chebyshev_distance(nbr.centroid.position, nbr.grid_position)
        #var ndist2 := Util.chebyshev_distance(nbr.centroid.position, nbr.grid_position)

        # Check distance from current position to neighbors centroid to see
        # what their new distance would be if they moved
        var ndist := grid_position.distance_to(nbr.boid.centroid.position)

        if ndist > dist2:
            return false

    nbr.move_to(current_tile)
    move_to(dest)

    return true


func move_towards(dest: Tile) -> bool:
    # var boid_tile := _apply_boid_calculation(dest)
    var boid_tile := boid.get_next_tile(dest)

    if boid_tile.grid_position == grid_position:
        return false

    var dir := Direction.by_delta(grid_position, boid_tile.grid_position)

    if not dir or dir == Direction.none:
        return false

    var res := _check_tile_at(grid_position + dir.vector)
    var next_tile := world.get_tile(grid_position + dir.vector)

    match res:
        Type.Tile.WALL:
            # if state == State.RETURN and Tag.has(next_tile, Tags.UNIT_SHIP):
            if brain.state_is(States.Unit.RETURN) and Tag.has(next_tile, Tags.UNIT_SHIP):
                reset()
                return true # We reset, so no action cost needed
            elif current_tile.type == Type.Tile.VOID:
                return _do_move_action(next_tile)

        Type.Tile.UNIT:
            # Has units, but not entities
            if not next_tile.has_entities:
                if _do_move_action(next_tile):
                    return true
        Type.Tile.ENTITY:
            pass
        _:
            return _do_move_action(next_tile)

    var dist := grid_position.distance_to(target.grid_position)
    var limit := 8

    if dist < 1.5:
        return false

    for adj_dir in dir.adjacent:
        #if (grid_position + adj_dir.vector == last_position and dist <= limit or
            #dir.orthogonal.has(last_direction)):
            #continue
        next_tile = world.get_tile(grid_position + adj_dir.vector)

        # DEBUG
        var query := world.query_tile(next_tile)
        if query == Type.Tile.WALL:
            pass

        var res2 := _check_tile_at(grid_position + adj_dir.vector)
        var query2 := world.query_tile(next_tile)

        if res2 != query2:
            pass

        match res2:
            Type.Tile.WALL, Type.Tile.ENTITY:
                continue
            Type.Tile.GRASS:
                return _do_move_action(next_tile)
            Type.Tile.UNIT:
                # Has units, but not entities
                if not next_tile.has_entities:
                    if _do_move_action(next_tile):
                        return true
        continue

    var cheby := Util.chebyshev_distance(grid_position, target.grid_position)
    if cheby <= limit:
        return false

    for ort_dir in dir.orthogonal:
        if grid_position + ort_dir.vector == last_position:
            continue

        var res3 := _check_tile_at(grid_position + ort_dir.vector)

        if res3 == Type.Tile.WALL:
            continue

        if res3 == Type.Tile.GRASS:
            next_tile = world.get_tile(grid_position + ort_dir.vector)
            return _do_move_action(next_tile)

    return false


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
    _go_idle()


func join_squad() -> void:
    last_player_tile = null
    brain.change_state(States.Unit.FOLLOW)
    player.add_unit(self)


func dismiss() -> void:
    last_player_tile = player.current_tile
    _go_idle()


func go_home() -> void:
    brain.change_state(States.Unit.RETURN)


func ride_enemy(enemy: Enemy) -> void:
    if riding_enemy: return
    enemy.add_unit(self)
    riding_enemy = enemy


func get_off_enemy() -> void:
    if not riding_enemy: return
    riding_enemy.remove_unit(self)

    move_to(world.get_closest_empty_tile(riding_enemy.current_tile))
    riding_enemy = null


func grab_object(obj: MultiTileEntity) -> bool:
    if obj.add_carrier(self):
        held_object = obj
        return true

    return false


func drop_object() -> void:
    if not held_object: return
    held_object.remove_carrier(self)
    held_object = null


func _go_idle() -> void:
    brain.change_state(States.Unit.IDLE)


func _do_move_action(dest: Tile) -> bool:
    # DEBUG
    # if world.query_tile(dest) == Type.Tile.WALL:
    #     pass

    if dest.has_units and not can_stack:
        return swap_with(dest)

    move_to(dest)
    return true


func _in_range_of_tether() -> bool:
    var limit := Globals.UNIT_SIGHT_RANGE
    var dest := player.unit_tether.tail.grid_position
    return Util.chebyshev_distance(grid_position, dest) <= limit


func _can_see_position(dest_pos: Vector2i) -> bool:
    var callback := func(ctx: DDARC.Context):
        var pos := ctx.grid_position
        var query := world.query_tile_at(pos)
        if (not world.in_bounds(pos) or
            query == Type.Tile.ENTITY or
            query == Type.Tile.WALL and not current_tile.type == Type.Tile.VOID):
                return true

    var raycast := DDARC.to_grid_position(
        grid_position,
        dest_pos,
        callback
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
        var any := false
        for unit in tile.get_all_units():
            if unit.time < world.time and unit.update():
                any = true
        if any:
            return _check_tile_at(pos)

    return res


func _broadcast_path() -> void:
    if path.is_empty(): return

    var hist := {}
    var tiles := current_tile.get_all_neighbors()

    for _i in 2:
        var new_tiles : Array[Tile] = []

        for tile in tiles:
            if hist.has(tile):
                continue
            hist[tile] = true

            for unit in tile.get_all_units():
                var empty_path := unit.path.is_empty()
                if unit.target == target and (empty_path or unit.path[0] != path[0]):
                    unit._receive_path(path)

            new_tiles.append(tile)


func _receive_path(_path: Array[Vector2i]) -> void:
    _path = _path.duplicate()
    while not _path.is_empty():
        var dist1 := Util.chebyshev_distance(_path[0], _path[-1])
        var dist2 := Util.chebyshev_distance(grid_position, _path[-1])
        if dist1 < dist2:
            path = _path
            return
        _path.pop_front()


func _update_glyph(_idle := false) -> void:
    match type:
        Type.Unit.RED:
            if upgraded:
                if _idle: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE)
            elif _idle: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL)
        Type.Unit.YELLOW:
            if upgraded:
                if _idle: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE)
            elif _idle: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL)
        Type.Unit.BLUE:
            if upgraded:
                if _idle: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE)
            elif _idle: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL)
