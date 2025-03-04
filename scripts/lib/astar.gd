class_name AStar extends AStarGrid2D

## Customized [AStarGrid2D] node to work specifically for Roguemin.

## The world this object is attached to.
var world : World

# The cached entity committing the search.
var _entity : Entity


func _init(_world: World) -> void:
    world = _world
    jumping_enabled = true


func _compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
    var tile := world.get_tile(from_id)
    var dest := world.get_tile(to_id)

    # Check for walls
    if world.query_tile(dest) == Type.Tile.WALL and not world.query_tile(tile) == Type.Tile.VOID:
        return INF
    
    # Check for hazards

    return from_id.distance_to(to_id)


func get_path_to(ent: Entity, pos: Vector2i) -> Array[Vector2i]:
    _entity = ent
    return get_id_path(ent.grid_position, pos)