class_name AStarChunks extends AStarGrid2D

## Customized [AStarGrid2D] node to navigate the chunks of the [World].

## The world this object is attached to.
var world : World

func _init(_world: World) -> void:
    world = _world
    jumping_enabled = true
    region = Rect2i(1, 1, world.size.x-2, world.size.y-2)

