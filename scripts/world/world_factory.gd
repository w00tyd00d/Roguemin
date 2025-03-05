class_name WorldFactory extends RefCounted

## Factory class responsible for procedurally generating new [World] objects.

# World Generation Algorithm Steps:
#
# 1. Place Base room down
#
# 2. Place Prefab rooms down
# 	- Determine chance of walls and how many
#
# 3. Place Procgen rooms down
# 	- Determine which faces will have exits and where (1 per?)
# 	- Determine chance of walls and how many
#
# 4. Begin walking through nodes at somewhat random to try and connect threshold
#    nodes together
#
# 5. Once all nodes are connected on a single tree internally, begin connecting
#    them on the tilemap
#    - Change the Tile's internal metadata as it goes as well
#
# 6. Once all connections have been drawn, create Flow Field matrix starting from
#    the "return point" cell within the base room. Add any new wall found
#    to an array that will be iterated on in step 7.
#
# 7. From every wall within the cached walls array, create a Dijkstra map to
#    record the distance away that cell is from a wall (up to a max of 7)
#
# 8. Begin placement of enemies and salvageables

const WORLD_SIZE := Vector2i(20,20)

func create_new_world() -> World:
    var world := World.create()
    world.setup(WORLD_SIZE)
    return world


func setup_world(world: World) -> World:
    _generate_rooms(world)
    return world


func _generate_rooms(world: World) -> void:
    _place_room(world, Vector2i(1,1), Rooms.HOME_BASE)


func _place_room(world: World, chunk_pos: Vector2i, room: RoomBlueprint) -> void:
    # Link the chunks
    for dy in room.size.y:
        for dx in room.size.x:
            var delta := Vector2i(dx, dy)
            var chunk := world.get_chunk(chunk_pos + delta)

            if dx != 0: chunk.add_edge(Direction.west, Type.ChunkEdge.ROOM)
            if dy != 0: chunk.add_edge(Direction.north, Type.ChunkEdge.ROOM)
            if dx != room.size.x-1: chunk.add_edge(Direction.east, Type.ChunkEdge.ROOM)
            if dy != room.size.y-1: chunk.add_edge(Direction.south, Type.ChunkEdge.ROOM)

    # Place down the room tile by tile
    var start := world.get_chunk(chunk_pos).start
    
    for pos: Vector2i in room.tile_data:
        var glyph : Glyph = room.tile_data[pos]
        var dpos := start + pos

        if glyph.matches(Glyph.GRASS):
            var choices := [Glyph.GRASS, Glyph.SHRUB]
            var weights := PackedFloat32Array([1, .01])
            var idx := GameState.RNG.rand_weighted(weights)

            glyph = choices[idx]
            world.set_tile_type(dpos, Type.Tile.GRASS)
            
        # ADD WATER TILES
            
        else:
            world.set_tile_type(dpos, Type.Tile.WALL)

        world.set_glyph(dpos, glyph)

    room._run_context_procedures(world, start)
