class_name AStarTiles extends AStarGrid2D

## Customized [AStarGrid2D] node to navigate the tiles of the [World].

## The world this object is attached to.
var world : World

# The cached entity committing the search.
# var _entity : Entity


func _init(_world: World) -> void:
    world = _world
    jumping_enabled = true


func _compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
    var tile := world.get_tile(from_id)
    var dest := world.get_tile(to_id)

    var query_self := world.query_tile(tile)
    var query_dest := world.query_tile(dest)

        # Check for walls
    if (query_dest == Type.Tile.WALL and not query_self == Type.Tile.VOID or
        # Check for entities
        query_dest == Type.Tile.ENTITY and not query_self == Type.Tile.ENTITY):
        return INF

    # Check for hazards

    return from_id.distance_to(to_id)


# func find_path_to(pos: Vector2i, dest: Vector2i) -> Array[Vector2i]:
#     # _entity = ent
#     return get_id_path(pos, dest)
