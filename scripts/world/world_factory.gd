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

const WORLD_SIZE := Vector2i(17,17)

var _wall_tiles : Array[Tile] = []


func create_new_world() -> World:
    var world := World.create()
    world.setup(WORLD_SIZE)
    return world


func setup_world(world: World) -> World:
    _generate_rooms(world)
    _generate_flow_field(world)
    _generate_wall_dijkstra_map(world)
    _generate_enemies(world)
    return world


func _generate_rooms(world: World) -> void:
    _place_room(world, Vector2i(1,1), Rooms.HOME_BASE)


func _generate_flow_field(world: World) -> void:
    var start := world.salvage_return_tile

    start._flow_field_value = 0

    var hist := {}
    var tiles : Array[Tile] = [start]

    while not tiles.is_empty():
        var new_tiles : Array[Tile] = []

        for tile in tiles:
            hist[tile] = true
            for nbr in tile.get_all_neighbors():
                if hist.has(nbr) or nbr.type == Type.Tile.VOID:
                    continue

                if tile.type == Type.Tile.WALL:
                    _wall_tiles.append(tile)
                    continue

                var dir := Direction.by_delta(tile.grid_position, nbr.grid_position)
                var cost := 7 if dir.is_diagonal else 5
                var val := tile._flow_field_value + cost

                if nbr._flow_field_value > val:
                    nbr._flow_field_value = val
                    nbr._flow_field_vector = nbr._get_best_flow_field_vector()
                    new_tiles.append(nbr)

        tiles = new_tiles


func _generate_wall_dijkstra_map(_world: World) -> void:
    var hist := {}
    var tiles := _wall_tiles
    var step := 1

    while not tiles.is_empty() and step < 7:
        var new_tiles : Array[Tile] = []
        for tile in tiles:
            for nbr in tile.get_all_neighbors():
                if hist.has(nbr) or nbr.type == Type.Tile.VOID:
                    continue
                nbr._distance_from_wall = step
                new_tiles.append(nbr)
                hist[nbr] = true

        tiles = new_tiles
        step += 1


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
            world.astar.set_point_solid(dpos, true)

        world.set_glyph(dpos, glyph)

    room._run_context_procedures(world, start)


func _generate_enemies(world: World) -> void:
    # Place Spotty Red enemy at specific location for now
    var pos := world.get_chunk(Vector2i(2,1)).center
    
    world.spawn_entity(SmallTreasure, pos)



