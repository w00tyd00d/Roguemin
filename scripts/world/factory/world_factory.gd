class_name WorldFactory extends RefCounted

## Factory class responsible for procedurally generating new [World] objects.

var RNG := GameState.RNG
var CARDINALS : Array[Direction] = [
    Direction.north,
    Direction.south,
    Direction.east,
    Direction.west
]

var architect := WorldArchitect.new()
var navigator := WorldNavigator.new()
var populator := WorldPopulator.new()

var unit_container : UnitContainer # Assigned by GameScreen at runtime


func generate_new_world(viewport: SubViewport) -> World:
    var world := _create_new_world()
    viewport.add_child(world)

    # Din
    architect.generate_rooms(world)
    architect.generate_exits(world)
    architect.generate_paths(world)

    # Nayru
    navigator.generate_flow_field(world)
    navigator.generate_wall_dijkstra_map(world)

    # Farore
    populator.generate_enemies(world)
    populator.generate_treasure(world)

    return world


func _create_new_world() -> World:
    var world := World.create()
    world.setup(Globals.WORLD_SIZE)
    world.unit_container = unit_container
    
    for _x in world.size.x:
        world.get_chunk(Vector2i(_x, 0)).type = Type.Chunk.BORDER
        world.get_chunk(Vector2i(_x, world.size.y-1)).type = Type.Chunk.BORDER
    for _y in world.size.y-2:
        world.get_chunk(Vector2i(0, _y+1)).type = Type.Chunk.BORDER
        world.get_chunk(Vector2i(world.size.x-1, _y+1)).type = Type.Chunk.BORDER

    return world