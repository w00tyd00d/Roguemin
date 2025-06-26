class_name Entity extends DualMapLayer

## The base class for all entities in the game.

var current_tile : Tile :
    get:
        if not GameState.world: return null
        return GameState.world.get_tile(grid_position)

## The cached last position of the entity.
var last_position : Vector2i

## The in-game name of the entity.
var entity_name := "Unknown Entity"

## The value of time the entity has been synced up to.
var time := 0

## The amount of energy points the entity has accumulated.
var action_energy := 0

## The amount of posture points the entity currently has.
# DEPRECATE THIS!
var posture_points := 0

## Flag for signaling if the entity can act on this turn.
var can_act : bool : get = _get_can_act

## Dictionary of immunities the entity has.
var _immunities := {}


func move_to(dest: Tile) -> void:
    GameState.world.move_entity(self, dest)
    last_position = grid_position
    grid_position = dest.grid_position


func move_towards(target: Tile) -> bool:
    var world := GameState.world
    var delta := target.grid_position - grid_position
    var ax := absi(delta.x)
    var ay := absi(delta.y)

    var vec : Vector2i

    if ax >= ay * 2: vec = Vector2i(delta.sign().x, 0)
    elif ay >= ax * 2: vec = Vector2i(0, delta.sign().y)
    else: vec = delta.sign()

    var dir := Direction.by_pattern(vec)

    if world.query_tile_at(grid_position + dir.vector) == Type.Tile.GRASS:
        var dest = world.get_tile(grid_position + dir.vector)
        move_to(dest)
        return true

    for _dir in dir.adjacent:
        if grid_position + _dir.vector == last_position: continue
        if world.query_tile_at(grid_position + _dir.vector) == Type.Tile.GRASS:
            var dest = world.get_tile(grid_position + _dir.vector)
            move_to(dest)
            return true

    return false


func update() -> bool:
    var world_time := maxi(time, GameState.world.time)
    var time_units := world_time - time

    time = world_time

    return add_and_check_energy(time_units)


func do_action() -> bool:
    return false


func add_and_check_energy(time_units: int) -> bool:
    # If we already can act, refund the points if the action fails
    if can_act:
        if do_action():
            return can_act
        action_energy -= time_units
        return false

    # Otherwise, we can continue to accumulate    
    action_energy += time_units
    
    if can_act: do_action()

    return can_act


func add_immunity(hazard: Type.Hazard) -> void:
    _immunities[hazard] = true


func has_immunity(hazard: Type.Hazard) -> bool:
    return _immunities.has(hazard)


func remove_immunity(hazard: Type.Hazard) -> void:
    _immunities.erase(hazard)


func reset_immunities() -> void:
    _immunities = {}


func _get_can_act() -> bool:
    return action_energy >= Globals.DEFAULT_ENERGY_STEP
