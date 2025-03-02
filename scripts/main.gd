extends Node

var world_factory := WorldFactory.new()

@onready var game_viewport := $GameScreen/%SubViewport as SubViewport

func _ready() -> void:
    # Set the default background color to black at runtime
    RenderingServer.set_default_clear_color(Color.BLACK)

    # Immediately create new world for now
    var world := world_factory.create_new_world()
    game_viewport.add_child(world)
    world_factory.setup_world(world)

    # Immediate create the player character for now
    var player := Player.create()
    game_viewport.add_child(player)

    GameState.world = world
    GameState.player = player
    
    player.move_to(world.get_tile(Vector2i(15, 15)))