class_name AStarChunks extends AStarGrid2D

## Customized [AStarGrid2D] node to navigate the chunks of the [World].

## The world this object is attached to.
var world : World

func _init(_world: World) -> void:
    world = _world
    jumping_enabled = true
    # diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    region = Rect2i(1, 1, world.size.x-2, world.size.y-2)
    update()


func get_full_path(chunk1: Chunk, chunk2: Chunk) -> Array[Vector2i]: 
    var jps_path := get_id_path(chunk1.chunk_position, chunk2.chunk_position)
    
    if jps_path.is_empty():
        return []
    
    var res : Array[Vector2i] = [jps_path[0]]

    for i in range(jps_path.size()-1):
        var ptr := jps_path[i]
        var dst := jps_path[i+1]
        var vec := Direction.by_delta(ptr, dst).vector
        while ptr != dst:
            ptr += vec
            res.append(ptr)

    return res
