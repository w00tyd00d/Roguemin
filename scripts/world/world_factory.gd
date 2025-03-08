class_name WorldFactory extends RefCounted

## Factory class responsible for procedurally generating new [World] objects.

var RNG := GameState.RNG
var CARDINALS : Array[Direction] = [
    Direction.north,
    Direction.south,
    Direction.east,
    Direction.west
]

var _wall_tiles : Array[Tile] = []

var _path_heads : Array[World.Chunk] = []


func create_new_world() -> World:
    var world := World.create()
    world.setup(Globals.WORLD_SIZE)
    return world


func setup_world(world: World) -> World:
    for _x in world.size.x:
        world.get_chunk(Vector2i(_x, 0)).type = Type.Chunk.BORDER
        world.get_chunk(Vector2i(_x, world.size.y-1)).type = Type.Chunk.BORDER
    for _y in world.size.y-2:
        world.get_chunk(Vector2i(0, _y+1)).type = Type.Chunk.BORDER
        world.get_chunk(Vector2i(world.size.x-1, _y+1)).type = Type.Chunk.BORDER
        
    _generate_rooms(world)
    _generate_exits(world)
    
    _generate_flow_field(world)
    _generate_wall_dijkstra_map(world)

    _generate_enemies(world)

    return world


func _generate_rooms(world: World) -> void:
    var base_x := RNG.randi_range(2, world.size.x-2)
    var base_y := RNG.randi_range(2, world.size.y-2)

    _place_room(world, 0, Vector2i(base_x, base_y), Rooms.HOME_BASE)
    world.get_chunk(Vector2i(base_x-1, base_y+1))

    for id in range(1, RNG.randi_range(6,8)):
        var room := Rooms.ALL_ROOMS.pick_random() as RoomBlueprint

        var room_pos := Vector2i()
        while room_pos == Vector2i():
            var rx := RNG.randi_range(1, world.size.x-1)
            var ry := RNG.randi_range(1, world.size.y-1)
            if _check_for_room_collision(world, rx, ry):
                continue
            room_pos = Vector2i(rx, ry)
        
        _place_room(world, id, room_pos, room)
        


    
func _check_for_room_collision(world: World, x: int, y: int) -> bool:
    for _y in y:
        for _x in x:
            if world.get_chunk(Vector2i(_x, _y)).type != Type.Chunk.NONE:
                return true
    return false
            
            
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


func _place_room(
        world: World,
        room_id: int,
        chunk_pos: Vector2i,
        blueprint: RoomBlueprint) -> void:
    
    var chunks: Array[World.Chunk] = []
    var room := Room.new(blueprint.size, chunk_pos, chunks)
            
    # Link the chunks
    for dy in blueprint.size.y:
        for dx in blueprint.size.x:
            var delta := Vector2i(dx, dy)
            var chunk := world.get_chunk(chunk_pos + delta)

            chunk.type = Type.Chunk.ROOM
            chunk.room = room
            chunks.append(chunk)

            if dx != 0: chunk.add_edge(Direction.west, Type.Chunk.ROOM)
            if dy != 0: chunk.add_edge(Direction.north, Type.Chunk.ROOM)
    
    # Store the room chunk locations to the world
    world.rooms[room_id] = room

    # Place down the room tile by tile
    var start := world.get_chunk(chunk_pos).start

    for pos: Vector2i in room.tile_data:
        var glyph : Glyph = room.tile_data[pos]
        var dpos := start + pos

        if glyph.matches(Glyph.GRASS):
            var choices := [Glyph.GRASS, Glyph.SHRUB]
            var weights := PackedFloat32Array([1, .01])
            var idx := RNG.rand_weighted(weights)

            glyph = choices[idx]
            world.set_tile_type(dpos, Type.Tile.GRASS)

        else:
            world.set_tile_type(dpos, Type.Tile.WALL)
            world.astar.set_point_solid(dpos, true)

        world.set_glyph(dpos, glyph)

    room._run_context_procedures(world, start)


func _generate_exits(world: World) -> void:
    for room: Room in world.rooms.values():
        var exit_count := RNG.randi_range(1,4)
        var sides_left : Array[Direction] = CARDINALS.duplicate()
        sides_left.shuffle()

        while exit_count > 0 and sides_left.size() > 0:
            var dir := sides_left[-1]
            
            if room.exits.has(dir):
                sides_left.pop_back()
                continue
            
            if _establish_exit(world, room, dir):
                exit_count -= 1
            
            sides_left.pop_back()
        
    # Double check that we don't have any isolated room clusters
    for room: Room in world.rooms.values():
        if room.open: continue
        for dir in room.exits:
            var chunk := world.get_chunk(room.exits[dir] as Vector2i)
            assert(chunk.room)
            if chunk.room.open:
                break

        var dirs := CARDINALS.duplicate()
        dirs.shuffle()
                
        for dir in dirs:
            if dir in room.exits: continue
            if _establish_exit(world, room, dir): break
                



func _establish_exit(world: World, room: Room, dir: Direction) -> bool:
    var pos := room.chunk_position
    
    match dir:
        Direction.north, Direction.south:
            var oy := 0 if Direction.north else room.size.y-1
            var rx := RNG.randi_range(0, room.size.x-1)
            var dvec := Vector2i(rx, dir.vector.y + oy)
            var nbr := world.get_chunk(pos + dvec)
            if nbr.type == Type.Chunk.BORDER:
                return false
            elif nbr.type == Type.Chunk.ROOM:
                nbr.room.exits[dir.opposite] = pos + dvec
            else:
                nbr.type = Type.Chunk.PATH
                _path_heads.append(nbr)
                room.open = true
            
            room.exits[dir] = pos + Vector2i(rx, oy)
            world.get_chunk(pos + Vector2i(rx, oy)).add_edge(dir, Type.Chunk.EXIT)

        Direction.west, Direction.east:
            var ox := 0 if Direction.west else room.size.x-1
            var ry := RNG.randi_range(0, room.size.y-1)
            var dvec := Vector2i(dir.vector.x + ox, ry)
            var nbr := world.get_chunk(pos + dvec)
            if nbr.type == Type.Chunk.BORDER:
                return false
            elif nbr.type == Type.Chunk.ROOM:
                nbr.room.exits[dir.opposite] = pos + dvec
            else:
                nbr.type = Type.Chunk.PATH
                _path_heads.append(nbr)
                room.open = true
            
            room.exits[dir] = pos + Vector2i(ox, ry)
            world.get_chunk(pos + Vector2i(ox, ry)).add_edge(dir, Type.Chunk.EXIT)

    return true


func _generate_enemies(world: World) -> void:
    # Place Spotty Red enemy at specific location for now
    var pos := world.get_chunk(Vector2i(2,1)).center
    
    world.spawn_entity(SpottyRed, pos)


class Room:
    var size : Vector2i
    var chunk_position : Vector2i
    var chunk_area : Array[World.Chunk]

    var exits := {}
    var open := false

    func _init(
            _size: Vector2i,
            pos: Vector2i,
            area: Array[World.Chunk]) -> void:
        
        size = _size
        chunk_position = pos
        chunk_area = area


class Walker:

    var chunk_position := Vector2i()
    var stack : Array[World.Chunk] = []
    var history := {}

    
    