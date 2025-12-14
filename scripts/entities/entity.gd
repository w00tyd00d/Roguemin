class_name Entity extends DualMapLayer

## The base class for all entities in the game.

var RNG : RandomNumberGenerator :
    get: return GameState.RNG

var world : World :
    get: return GameState.world

var player : Player :
    get: return GameState.player

var current_tile : Tile :
    get:
        if not world: return null
        return world.get_tile(grid_position)

## The cached last position of the entity.
var last_position : Vector2i

## The last direction the entity had traveled
var last_direction : Direction :
    get:
        if last_position == Vector2i(): return Direction.none
        return Direction.by_delta(last_position, grid_position)

## The last vector the entity had traveled
var last_velocity : Vector2i :
    get: return last_direction.vector

## The brain of the entity
var brain : Brain

## The in-game name of the entity.
var entity_name := "Unknown Entity"

# ## The value of time the entity has been synced up to.
var time : int :
    set(n): brain.time = n
    get: return brain.time

# ## The amount of energy points the entity has accumulated.
# var action_energy := 0

# ## The amount of posture points the entity currently has.
# # DEPRECATE THIS!
# var posture_points := 0

## Flag for signaling if the entity can act on this turn.
var can_act : bool :
    get: return brain.can_act

## Dictionary of immunities the entity has.
var _immunities := {}


func move_to(dest: Tile) -> void:
    world.move_entity(self, dest)


func move_towards(target: Tile) -> bool:
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
            var dest := world.get_tile(grid_position + _dir.vector)
            move_to(dest)
            return true

    return false


func update() -> bool:
    return brain.update()


func add_immunity(hazard: Type.Hazard) -> void:
    _immunities[hazard] = true


func has_immunity(hazard: Type.Hazard) -> bool:
    return _immunities.has(hazard)


func remove_immunity(hazard: Type.Hazard) -> void:
    _immunities.erase(hazard)


func reset_immunities() -> void:
    _immunities = {}
