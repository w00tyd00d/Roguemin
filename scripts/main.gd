extends Node

var world_factory := WorldFactory.new()

var game_started := false

@onready var main_screen := $MainScreen as Control
@onready var loading_screen := $LoadingScreen as Control
@onready var game_screen := $GameScreen as Control

@onready var game_viewport := $GameScreen/%SubViewport as SubViewport
@onready var unit_container := $GameScreen/%UnitContainer as UnitContainer

func _ready() -> void:
    # Set the default background color to black at runtime
    RenderingServer.set_default_clear_color(Color.BLACK)
    InputManager.add(_input_handler)

    GameState.new_game.connect(new_game)

    # We keep these nodes as a children to the game screen, but we inject
    # references to them to the world factory so that it may utilize them
    world_factory.unit_container = unit_container
    world_factory.game_viewport = game_viewport

    # FOR DEBUGGING PURPOSES, AUTOMATICALLY GO RIGHT TO GAME
    game_started = true
    await new_game()
    InputManager.add(GameState.player.controller.input_handler)
    

func initialize_game() -> void:
    var world := world_factory.generate_new_world()
    GameState.world = world

    unit_container.reset_all()

    var player : Player
    if not GameState.player:
        player = Player.create()
        game_viewport.add_child(player)
        GameState.player = player

    player = GameState.player
    player.test_layer = world.get_node("TEST")
    
    player.move_to(world.get_tile(world.start_position))
    player.unit_tether.reset()


func new_game() -> void:
    if GameState.world:
        GameState.world.queue_free()
    
    
    GameState.toggle_hud.emit(false)
    game_screen.hide()
    loading_screen.show()
    
    await get_tree().create_timer(0.2).timeout
    
    main_screen.hide()
    initialize_game()
    
    loading_screen.hide()
    game_screen.show()
    GameState.toggle_hud.emit(true)
    

func _input_handler(_dt: float) -> void:
    if not game_started:
        for inp in Globals.ACTION_INPUTS + Globals.DIRECTIONAL_INPUTS:
            if Input.is_action_pressed(inp):
                game_started = true
                await new_game()
                InputManager.add(GameState.player.controller.input_handler)
