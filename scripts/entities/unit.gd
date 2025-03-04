class_name Unit extends Entity

## The entity the [Player] controls to do tasks for them.

enum State {
    IDLE,
    FOLLOWING,
    ATTACKING,
    CARRYING
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
var target : Entity

## A cached path to the unit's target.
var path : Array

## A flag representing if the unit is idle.
var idle : bool :
    get: return state == State.IDLE


## A flag representing if the unit is in limbo (ie: not in the field).
var in_limbo : bool :
    get: return grid_position == Vector2i()


func _ready() -> void:
    add_to_group(&"units")


func reset() -> void:
    hide()
    energy_points = 0
    posture_points = 0

    grid_position = Vector2()

    if GameState.world:
        var count := GameState.world.unit_count
        GameState.world.unit_count = maxi(count-1, 0)


func spawn(pos: Vector2i, _type: Type.Unit, _upgraded := false) -> void:
    type = _type
    upgraded = _upgraded
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

    if _check_tile_at(grid_position + dir.vector) == Type.Tile.GRASS:
        var dest = world.get_tile(grid_position + dir.vector)
        move_to(dest)
        return true

    for _dir in dir.adjacent:
        if grid_position + _dir.vector == last_position: continue
        if _check_tile_at(grid_position + _dir.vector) == Type.Tile.GRASS:
            var dest = world.get_tile(grid_position + _dir.vector)
            move_to(dest)
            return true
    
    return false


func throw_to(tile: Tile) -> void:
    move_to(tile)
    go_idle()


func go_idle() -> void:
    state = State.IDLE
    GameState.player.remove_unit(self)


func join_squad() -> void:
    state = State.FOLLOWING
    GameState.player.add_unit(self)


func update_time(world_time: int) -> bool:
    var old_time := time
    time = world_time

    if not in_limbo:
        var time_units := time - old_time
        if add_and_check_energy(time_units):
            return do_action()
    
    return false


func do_action() -> bool:
    match state:
        State.FOLLOWING:
            if not GameState.player: return false

            var player := GameState.player
            var tether := player.unit_tether
            var dest := tether.tail.current_tile

            if not _in_range_of_tether():
                go_idle()
                return false
            
            if _can_see_tether():
                return move_towards(dest)
        
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
            world.query_tile_at(pos) == Type.Tile.WALL):
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
        
    
    # match world.query_tile(tile):
    #     Type.Tile.ENTITY:
    #         for unit in tile.get_all_units():
    #             if unit.time < GameState.world.time:
    #                 unit.update_time(world_time)

    #     Type.Tile.GRASS:
    #         var dest = world.get_tile(pos)
    #         move_to(dest)
    #         return true

    return res


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
        State.FOLLOWING:
            GameState.player.add_unit(self)
        

func _on_state_exit(_state: State) -> void:
    match _state:
        State.IDLE:
            _update_glyph()
        State.FOLLOWING:
            GameState.player.remove_unit(self)
