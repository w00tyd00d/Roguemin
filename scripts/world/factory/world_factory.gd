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

# Assigned by GameScreen at runtime
var unit_container : UnitContainer
var game_viewport : SubViewport 


func generate_new_world() -> World:
    var world := _create_new_world()
    
    # We add the world as a child first so that we can reference its children
    # when running it through the factory
    game_viewport.add_child(world)

    architect.run(world)
    navigator.run(world)
    populator.run(world)

    return world


func _create_new_world() -> World:
    var world := World.create()
    world.setup(Globals.WORLD_SIZE)
    world.unit_container = unit_container
    
    # Create a border of void chunks to surround the traversible world
    for _x in world.size.x:
        world.get_chunk(Vector2i(_x, 0)).type = Type.Chunk.VOID
        world.get_chunk(Vector2i(_x, world.size.y-1)).type = Type.Chunk.VOID
    for _y in world.size.y-2:
        world.get_chunk(Vector2i(0, _y+1)).type = Type.Chunk.VOID
        world.get_chunk(Vector2i(world.size.x-1, _y+1)).type = Type.Chunk.VOID

    return world