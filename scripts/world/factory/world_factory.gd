class_name WorldFactory extends RefCounted

## Factory class responsible for procedurally generating new [World] objects.

var RNG := GameState.RNG
var CARDINALS : Array[Direction] = [
    Direction.north,
    Direction.south,
    Direction.east,
    Direction.west
]

var architect := WorldArchitect.new() # Din
var navigator := WorldNavigator.new() # Nayru
var populator := WorldPopulator.new() # Farore

# Assigned by Main at runtime
var game_viewport : SubViewport 
var debug_mode := false


func generate_new_world() -> World:
    var world := _create_new_world()
    
    # We add the world as a child first so we can reference its children
    # when running it through the factory
    game_viewport.add_child(world)

    architect.run(world, debug_mode)
    navigator.run(world, debug_mode)
    populator.run(world, debug_mode)

    return world


func _create_new_world() -> World:
    var world := World.create()
    # world.unit_container = unit_container
    return world