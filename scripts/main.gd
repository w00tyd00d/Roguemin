extends Node

var world_factory := WorldFactory.new()

@onready var game_viewport := $GameScreen/%SubViewport as SubViewport
@onready var unit_container := $GameScreen/%UnitContainer as UnitContainer

func _ready() -> void:
    # Set the default background color to black at runtime
    RenderingServer.set_default_clear_color(Color.BLACK)

    ##### DEBUG ######
    #var cb := func(ctx: DDARC.Context): print(ctx.length)
    #var res := DDARC.to_grid_position(Vector2i(5,5), Vector2i(10,13), cb)
    #print(res.grid_position)
    #print(res.exact_position)
    #print(res.cell_path)
    #print(res.length)
#
    #return
    ##################

    # Immediately create new world for now
    var world := world_factory.create_new_world()
    game_viewport.add_child(world)
    world_factory.setup_world(world)
    print("Unit container is ", unit_container)
    world.unit_container = unit_container

    # Immediate create the player character for now
    var player := Player.create()
    game_viewport.add_child(player)

    GameState.world = world
    GameState.player = player

    player.test_layer = world.get_node("TEST")

    player.move_to(world.get_tile(world.start_position))
    player.unit_tether.reset()
