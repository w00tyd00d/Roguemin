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


func move_to(dest: Tile) -> void:
    grid_position = dest.grid_position
    GameState.world.move_entity(self, dest)
