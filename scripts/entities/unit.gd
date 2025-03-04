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
var state := State.FOLLOWING :
    set(new_state):
        _on_state_exit(state)
        _on_state_enter(new_state)

## The current target of the unit.
var target : Entity

## A cached path to the unit's target.
var path : Array

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


func update_time(world_time: int) -> void:
    var old_time := time
    time = world_time

    if not in_limbo:
        var time_units := time - old_time
        if add_and_check_energy(time_units):
            do_action()


func do_action() -> void:
    match state:
        State.FOLLOWING:
            if not GameState.player: return

            var player := GameState.player
            var tether := player.unit_tether
            var dest := tether.tail.current_tile

            if (_in_range_of_tether() and
                _can_see_tether()):
                    move_towards(dest)


func _in_range_of_tether() -> bool:
    var limit := 12
    var world := GameState.world
    var dest := GameState.player.unit_tether.tail.current_tile
    return world.chebyshev_distance(current_tile, dest) <= limit


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


func _update_glyph() -> void:
    match type:
        Type.Unit.RED:
            if upgraded: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE)
            else: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL)
        Type.Unit.YELLOW:
            if upgraded: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE)
            else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL)
        Type.Unit.BLUE:
            if upgraded: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE)
            else: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL)


func _on_state_enter(_state: State) -> void:
    match _state:
        State.FOLLOWING:
            GameState.player.add_unit(self)
        

func _on_state_exit(_state: State) -> void:
    match _state:
        State.FOLLOWING:
            GameState.player.remove_unit(self)
