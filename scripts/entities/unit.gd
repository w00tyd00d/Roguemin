class_name Unit extends Entity

## The entity the [Player] controls to do tasks for them.

enum State {
    IDLE,
    FOLLOW,
    ATTACK,
    CARRY,
    RETURN
}

## The current type of the unit.
var type : Type.Unit

## Returns if the unit has been upgraded or not.
var upgraded : bool


## The current state of the unit.
var state := State.IDLE :
    set(new_state):
        var old_state = state
        state = new_state
        _on_state_exit(old_state)
        _on_state_enter(new_state)
## The current target of the unit.
var target

## The object the unit is currently holding on to.
var held_object : MultiTileEntity

## A cached path to the unit's target.
var path : Array :
    set(arr):
        path = arr
        if not path.is_empty():
            GameState.ASTAR_TEST.emit(arr)

## A flag representing if the unit is idle.
var idle : bool :
    get: return state == State.IDLE

## A flag representing if the unit is in limbo (ie: not in the field).
var in_limbo : bool :
    get: return grid_position == Vector2i()

## The enemy the unit is current on top of, if at all.
var riding_enemy : Enemy



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
    energy_points = 0
    posture_points = 0

    var world := GameState.world
    GameState.player.remove_unit(self)
    current_tile.remove_unit(self)

    if held_object:
        drop_object()

    state = State.IDLE
    grid_position = Vector2()

    if world:
        var count := world.unit_count
        world.unit_count = maxi(count-1, 0)


func spawn(pos: Vector2i, _type: Type.Unit, _upgraded := false) -> void:
    type = _type
    upgraded = true # No time to implement nectar :(
    _update_glyph()

    grid_position = pos
    show()


func upgrade() -> void:
    if upgraded: return
    upgraded = true
    _update_glyph()


func die() -> void:
    # SETUP DEATH ANIMATION
    reset()


func move_to(dest: Tile) -> void:
    GameState.world.move_unit(self, dest)
    last_position = grid_position
    grid_position = dest.grid_position


func move_towards(tile: Tile) -> bool:
    var world := GameState.world
    var delta := tile.grid_position - grid_position
    var ax := absi(delta.x)
    var ay := absi(delta.y)

    var vec : Vector2i

    if ax >= ay * 2: vec = Vector2i(delta.sign().x, 0)
    elif ay >= ax * 2: vec = Vector2i(0, delta.sign().y)
    else: vec = delta.sign()

    var dir := Direction.by_pattern(vec)
    if not dir: return false

    var res := _check_tile_at(grid_position + dir.vector)
    var dest := world.get_tile(grid_position + dir.vector)

    if res == Type.Tile.WALL:
        if state == State.RETURN and Tag.has(dest, Tags.UNIT_SHIP):
            reset()
            return true
        elif current_tile.type == Type.Tile.VOID:
            move_to(dest)
            return true

    elif res != Type.Tile.WALL and res != Type.Tile.ENTITY:
        move_to(dest)
        return true

    var dist := grid_position.distance_to(tile.grid_position)
    if dist < 2: return false

    var limit := 11

    for adj_dir in dir.adjacent:
        if (grid_position + adj_dir.vector == last_position and dist <= limit):
            continue
        if _check_tile_at(grid_position + adj_dir.vector) == Type.Tile.GRASS:
            dest = world.get_tile(grid_position + adj_dir.vector)
            move_to(dest)
            return true

    if dist < limit:
        return false

    for ort_dir in dir.orthagonal:
        # if grid_position + ort_dir.vector == last_position: continue
        if _check_tile_at(grid_position + ort_dir.vector) == Type.Tile.GRASS:
            dest = world.get_tile(grid_position + ort_dir.vector)
            move_to(dest)
            return true

    return false


func throw_to(tile: Tile) -> void:
    var world := GameState.world
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
    move_to(tile)
    go_idle()


func go_idle() -> void:
    state = State.IDLE
    GameState.player.remove_unit(self)


func join_squad() -> void:
    state = State.FOLLOW
    GameState.player.add_unit(self)


func go_home() -> void:
    state = State.RETURN


func ride_enemy(enemy: Enemy) -> void:
    if riding_enemy: return
    enemy.add_unit(self)
    riding_enemy = enemy


func get_off_enemy() -> void:
    if not riding_enemy: return
    riding_enemy.remove_unit(self)
    
    move_to(GameState.world.get_closest_empty_tile(riding_enemy.current_tile))
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



func update_time(world_time: int) -> bool:
    var old_time := time
    time = world_time

    if not in_limbo:
        var time_units := time - old_time
        if add_and_check_energy(time_units):
            return do_action()

    return false


func do_action() -> bool:
    var world := GameState.world

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
            return move_towards(GameState.world.unit_ship_tile)

    return false


func _do_follow_action() -> bool:
    var player := GameState.player
    var world := GameState.world

    if not player: return false

    var tether := player.unit_tether
    var dest := tether.tail.current_tile

    if not _in_range_of_tether():
        go_idle()
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


func _in_range_of_tether() -> bool:
    var limit := Globals.UNIT_SIGHT_RANGE
    var dest := GameState.player.unit_tether.tail.grid_position
    return Util.chebyshev_distance(grid_position, dest) <= limit


func _can_see_tether() -> bool:
    var world := GameState.world
    var tail := GameState.player.unit_tether.tail

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
    var world := GameState.world
    var tile := world.get_tile(pos)
    var res := world.query_tile(tile)

    # Cascade forward to see if we can resolve movement
    if res == Type.Tile.ENTITY:
        var any := false
        for unit in tile.get_all_units():
            if unit.time < GameState.world.time and unit.update_time(world.time):
                any = true
        if any:
            return _check_tile_at(pos)

    return res


func _broadcast_path() -> void:
    var hist := {}
    var tiles := current_tile.get_all_neighbors()
    for _i in 2:
        var new_tiles : Array[Tile] = []
        for tile in tiles:
            if hist.has(tile): continue
            hist[tile] = true
            for unit in tile.get_all_units():
                if (unit.target == target and
                    unit.path.is_empty() or
                    unit.path[-1] != path[-1]):
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
    var player := GameState.player

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
