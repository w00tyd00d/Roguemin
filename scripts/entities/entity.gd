class_name Entity extends DualMapLayer

## The base class for all entities in the game.

var grid_position : Vector2i :
    set(vec):
        grid_position = vec
        position = vec * Globals.TILE_SIZE
        
var current_tile : Tile :
    get:
        if not GameState.world: return null
        return GameState.world.get_tile(grid_position)


## The amount of energy points the entity has accumulated.
var energy_points := 0

## The amount of posture points the entity currently has.
var posture_points := 0

## Flag for signaling if the entity can act on this turn.
var can_act : bool :
    get: return energy_points >= Globals.ENERGY_CAP


func move_to(dest: Tile) -> void:
    grid_position = dest.grid_position
    GameState.world.move_entity(self, dest)


func add_energy(amt: int) -> void:
    energy_points += amt