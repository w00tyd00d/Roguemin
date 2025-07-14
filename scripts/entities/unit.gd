class_name Unit extends Entity

## The entity the [Player] controls to do tasks for them.

enum State {
    IDLE,
    FOLLOW,
    ATTACK,
    CARRY,
    RETURN,
    DEAD
}

## The current type of the unit.
var type : Type.Unit

## Returns if the unit has been upgraded or not.
var upgraded : bool


## The current state of the unit.
var state := State.DEAD :
    set(new_state):
        var old_state = state
        state = new_state
        _on_state_exit(old_state)
        _on_state_enter(new_state)

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

## Cached result of the location of the units current boid centroid
var centroid : Vector2i

## A flag representing if the unit is idle.
var idle : bool :
    get: return state == State.IDLE

## A flag representing if the unit is in limbo (ie: not in the field).
var in_limbo : bool :
    get: return grid_position == Vector2i()

## A flag for whether not the unit is allowed to stack with other units
var can_stack : bool :
    get: return state == State.ATTACK


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


func update() -> bool:
    if in_limbo:
        time = maxi(time, world.time)
        return false
    return super()


func do_action() -> bool:
    centroid = Vector2i()

    match state:
        State.FOLLOW:
            return _do_follow_action()
        State.CARRY:
            if not held_object:
                if target.is_latch_position(grid_position):
                    grab_object(target)
                    return false
                return move_towards(target.current_tile)
        State.ATTACK:

            pass
        State.RETURN:
            return move_towards(world.unit_ship_tile)

    return false


func reset() -> void:
    hide()

    modulate.a = 1
    set_background(Vector2(), Glyph.BLACK)

    time = 0
    action_energy = 0
    posture_points = 0

    if player:
        player.remove_unit(self)

    if current_tile:
        current_tile.remove_unit(self)

    if not state == State.DEAD and world:
        var count := world.unit_count
        world.unit_count = maxi(count-1, 0)

    if held_object:
        drop_object()

    target = null
    state = State.IDLE
    grid_position = Vector2()
    last_player_tile = null

    centroid = Vector2i()


func spawn(pos: Vector2i, _type: Type.Unit, _upgraded := false) -> void:
    type = _type
    upgraded = true # No time to implement nectar :(
    state = State.FOLLOW if _in_range_of_tether() else State.IDLE
    grid_position = pos
    show()


func upgrade() -> void:
    if upgraded: return
    upgraded = true
    _update_glyph()


func die() -> void:
    state = State.DEAD

    player.remove_unit(self)
    current_tile.remove_unit(self)

    var count := world.unit_count
    world.unit_count = maxi(count-1, 0)

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
    last_position = grid_position
    grid_position = dest.grid_position


func swap_with(dest: Tile) -> bool:
    var units := dest.get_all_units()

    if units.size() > 1 or last_position == grid_position or centroid == Vector2i():
        return false

    var unit := units[0] as Unit
    var dist1 := grid_position.distance_to(centroid)
    var dist2 := unit.grid_position.distance_to(unit.centroid)

    if (centroid == Vector2i() or
        dest.grid_position.distance_to(centroid) > dist1 or
        unit.centroid != Vector2i() and
        grid_position.distance_to(unit.centroid) > dist2):
            return false

    units[0].move_to(current_tile)
    move_to(dest)

    return true


func move_towards(tile: Tile) -> bool:
    var delta := tile.grid_position - grid_position
    var ax := absi(delta.x)
    var ay := absi(delta.y)

    var vec : Vector2i

    if ax >= ay * 2: vec = Vector2i(delta.sign().x, 0)
    elif ay >= ax * 2: vec = Vector2i(0, delta.sign().y)
    else: vec = delta.sign()

    var dir := Direction.by_pattern(vec)
    if not dir: return false

    tile = _apply_boid_calculation(tile)
    if tile == current_tile:
        return false

    var res := _check_tile_at(grid_position + dir.vector)
    var dest := world.get_tile(grid_position + dir.vector)

    match res:
        Type.Tile.WALL:
            if state == State.RETURN and Tag.has(dest, Tags.UNIT_SHIP):
                reset()
                return true # We reset, so no action cost needed
            elif current_tile.type == Type.Tile.VOID:
                return _do_move_action(dest)

        Type.Tile.ENTITY:
            # Has units, but not entities
            if not tile.has_entities:
                if _do_move_action(dest):
                    return true
            # pass
        _:
            return _do_move_action(dest)

    var dist := grid_position.distance_to(tile.grid_position)
    # if dist < 1.5: return false

    var limit := 11

    for adj_dir in dir.adjacent:
        if (grid_position + adj_dir.vector == last_position and dist <= limit or
            dir.orthogonal.has(last_direction)):
            continue
        if _check_tile_at(grid_position + adj_dir.vector) == Type.Tile.GRASS:
            dest = world.get_tile(grid_position + adj_dir.vector)
            return _do_move_action(dest)

    if dist < limit:
        return false

    for ort_dir in dir.orthogonal:
        # if grid_position + ort_dir.vector == last_position: continue
        if _check_tile_at(grid_position + ort_dir.vector) == Type.Tile.GRASS:
            dest = world.get_tile(grid_position + ort_dir.vector)
            return _do_move_action(dest)

    return false


func throw_to(tile: Tile) -> void:
    last_player_tile = player.current_tile

    if tile.has_entities:
        var ent := tile.get_first_entity()
        if ent:
            match ent.type:
                Type.Entity.TREASURE:
                    var latch := ent.get_open_latch_tile()
                    if latch:
                        target_entity(ent)
                        move_to(latch)
                        grab_object(ent)
                        return

        tile = world.get_closest_empty_tile(tile)

    action_energy = 0

    move_to(tile)
    _go_idle()


func join_squad() -> void:
    last_player_tile = null
    state = State.FOLLOW
    player.add_unit(self)


func dismiss() -> void:
    last_player_tile = player.current_tile
    _go_idle()


func go_home() -> void:
    state = State.RETURN


func ride_enemy(enemy: Enemy) -> void:
    if riding_enemy: return
    enemy.add_unit(self)
    riding_enemy = enemy


func get_off_enemy() -> void:
    if not riding_enemy: return
    riding_enemy.remove_unit(self)

    move_to(world.get_closest_empty_tile(riding_enemy.current_tile))
    riding_enemy = null


func target_entity(ent: MultiTileEntity) -> void:
    target = ent
    match ent.type:
        Type.Entity.TREASURE: state = State.CARRY
        Type.Entity.ENEMY: state = State.ATTACK


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
    state = State.IDLE
    player.remove_unit(self)


func _do_follow_action() -> bool:
    if not player: return false

    var tether := player.unit_tether
    var dest := tether.tail.current_tile

    if not _in_range_of_tether():
        _go_idle()
        return false

    if _can_see_tether():
        return move_towards(dest)
    else:
        if (path.is_empty() or
            Util.chebyshev_distance(path[-1], target.grid_position) > 5):
                path = world.astar.find_path_to(self, dest.grid_position)
                _broadcast_path()

        var dist := Util.chebyshev_distance(current_tile.grid_position, path[0])
        if dist < 2:
            path.pop_front()
        if not path.is_empty():
            return move_towards(world.get_tile(path[0]))

    return false


func _apply_boid_calculation(dest: Tile) -> Tile:
    var area := Util.get_square_around_pos(grid_position, 5, true)

    var cohesion_sum := Vector2i()
    var alignment_sum := Vector2i()
    var avoidance_sum := Vector2i()

    var count := 0

    for pos in area:
        if pos == grid_position: continue

        var tile := world.get_tile(pos)
        var dist := Util.chebyshev_distance(tile.grid_position, grid_position)

        if tile.has_units:
            var same_units := tile.get_units(type)

            if not same_units.is_empty():
                cohesion_sum += tile.grid_position
                alignment_sum += same_units[0].last_velocity
                count += 1

                if dist == 1:
                    avoidance_sum += grid_position - tile.grid_position

        if (dist == 1 and (tile.has_entities or
            current_tile.walkable and tile.type == Type.Tile.WALL)):
            avoidance_sum += grid_position - tile.grid_position

    var cohesion := Vector2()
    var alignment := Vector2()

    if count > 0:
        var _centroid := Vector2(cohesion_sum) / count
        centroid = _centroid

        Vector2(_centroid - Vector2(grid_position)).normalized()
        Vector2(Vector2(alignment_sum) / count - Vector2(last_velocity)).normalized()

    var avoidance := Vector2(avoidance_sum).normalized()
    var destination := Vector2(dest.grid_position - grid_position).normalized()

    var vector := (
        cohesion * Globals.BOID_COHESION_WEIGHT +
        alignment * Globals.BOID_ALIGNMENT_WEIGHT +
        avoidance * Globals.BOID_AVOIDANCE_WEIGHT +
        destination * Globals.BOID_DESTINATION_WEIGHT
    ).normalized()

    var result : Tile

    if is_equal_approx(vector.x, vector.y):
        if is_zero_approx(vector.x):
            result = current_tile
        else:
            var dir := Direction.by_pattern(Vector2i(vector.sign()))
            var adj := dir.adjacent.pick_random() as Direction
            result = current_tile.get_neighbor(adj)
    else:
        var dir := Direction.by_pattern(Vector2i(vector.round()))
        result = current_tile.get_neighbor(dir)

    return result


func _do_move_action(dest: Tile) -> bool:
    # ALLOW TO BE MODIFIED BY BEING BOOSTED WITH SPICY SPRAY
    # AND RUSH BOOTS!
    var cost := Globals.DEFAULT_ENERGY_STEP - 10

    if dest.has_units and not can_stack:
        if not swap_with(dest):
            return false
    else:
        move_to(dest)

    # move_to(dest)

    action_energy -= cost
    return true


func _spend_attack_action() -> bool:
    # ALLOW TO BE MODIFIED BY BEING BOOSTED WITH SPICY SPRAY
    # AND POSSIBLY RUSH BOOTS!
    var cost := Globals.DEFAULT_ENERGY_STEP

    action_energy -= cost
    return true


func _in_range_of_tether() -> bool:
    var limit := Globals.UNIT_SIGHT_RANGE
    var dest := player.unit_tether.tail.grid_position
    return Util.chebyshev_distance(grid_position, dest) <= limit


func _can_see_tether() -> bool:
    var tail := player.unit_tether.tail

    var callback := func(ctx: DDARC.Context):
        var pos := ctx.grid_position
        if (not world.in_bounds(pos) or
            world.query_tile_at(pos) == Type.Tile.WALL and not
            current_tile.type == Type.Tile.VOID):
                return true

    var raycast := DDARC.to_grid_position(
        grid_position,
        tail.grid_position,
        callback)

    return raycast.grid_position == tail.grid_position


func _check_tile_at(pos: Vector2i) -> Type.Tile:
    var tile := world.get_tile(pos)
    var res := world.query_tile(tile)

    # Cascade forward to see if we can resolve movement
    if res == Type.Tile.ENTITY:
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
            if hist.has(tile): continue
            hist[tile] = true
            for unit in tile.get_all_units():
                var empty_path := unit.path.is_empty()
                if (unit.target == target and empty_path or
                    not empty_path and unit.path[-1] != path[-1]):
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


func _update_glyph() -> void:
    match type:
        Type.Unit.RED:
            if upgraded:
                if idle: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE)
            elif idle: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL)
        Type.Unit.YELLOW:
            if upgraded:
                if idle: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE)
            elif idle: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL)
        Type.Unit.BLUE:
            if upgraded:
                if idle: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE)
            elif idle: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL)


func _on_state_enter(_state: State) -> void:
    match _state:
        State.IDLE:
            _update_glyph()
        State.FOLLOW:
            target = player.unit_tether.tail
            player.add_unit(self)
        State.ATTACK:
            player.remove_unit(self)
        State.CARRY:
            player.remove_unit(self)


func _on_state_exit(_state: State) -> void:
    match _state:
        State.IDLE:
            _update_glyph()
        State.CARRY:
            drop_object()
