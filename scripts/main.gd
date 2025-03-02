extends Node

var world_factory := WorldFactory.new()

func _ready() -> void:
    # Immediately create new world for now
    var world := world_factory.create_new_world()
    add_child(world)

    world_factory.setup_world(world)


    GameState.world = world