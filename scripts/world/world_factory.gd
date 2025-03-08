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

var _walkers : Array[Walker] = []


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
    _generate_paths(world)

    _generate_flow_field(world)
    _generate_wall_dijkstra_map(world)

    _generate_enemies(world)
    _generate_treasure(world)

    return world


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

    for pos: Vector2i in blueprint.tile_data:
        var glyph : Glyph = blueprint.tile_data[pos]
        var dpos := start + pos

        if glyph.matches(Glyph.GRASS):
            var choices := [Glyph.GRASS, Glyph.SHRUB]
            var weights := PackedFloat32Array([1, .01])
            var idx := RNG.rand_weighted(weights)

            glyph = choices[idx]
            world.set_tile_type(dpos, Type.Tile.GRASS)
            world.fog_of_war.set_cell(dpos, -1, Vector2i(-1,-1), -1)

        else:
            world.set_tile_type(dpos, Type.Tile.WALL)
            world.astar.set_point_solid(dpos, true)
            world.mrpas.set_transparent(dpos, Type.Tile.WALL)

        world.set_glyph(dpos, glyph)
        if blueprint is MainBaseBlueprint:
            world.fog_of_war.set_cell(dpos, -1, Vector2i(-1,-1), -1)

    # blueprint._run_context_procedures(world, start)


func _generate_rooms(world: World) -> void:
    var base_x := RNG.randi_range(2, world.size.x-5)
    var base_y := RNG.randi_range(2, world.size.y-4)

    _place_room(world, 0, Vector2i(base_x, base_y), Rooms.HOME_BASE)
    var top := world.get_chunk(Vector2i(base_x, base_y+1))
    var lft := world.get_chunk(Vector2i(base_x+1, base_y))
    var bot := world.get_chunk(Vector2i(base_x+1, base_y+1))
    var rgt := world.get_chunk(Vector2i(base_x+2, base_y+1))

    top.add_edge(Direction.west, Type.Chunk.EXIT)
    lft.add_edge(Direction.north, Type.Chunk.EXIT)
    bot.add_edge(Direction.south, Type.Chunk.EXIT)
    rgt.add_edge(Direction.east, Type.Chunk.EXIT)

    _walkers.append(Walker.new(world, top, true))
    _walkers.append(Walker.new(world, lft, true))
    _walkers.append(Walker.new(world, bot, true))
    _walkers.append(Walker.new(world, rgt, true))

    for id in range(1, RNG.randi_range(3,4)):
        var blueprint := Rooms.ALL_ROOMS.pick_random() as RoomBlueprint

        var attempts := 0
        var room_pos := Vector2i()
        while room_pos == Vector2i() and attempts < 10:
            var rx := RNG.randi_range(1, world.size.x-1)
            var ry := RNG.randi_range(1, world.size.y-1)
            if _check_for_room_collision(world, Vector2i(rx, ry), blueprint):
                continue
            room_pos = Vector2i(rx, ry)
            attempts += 1

        _place_room(world, id, room_pos, blueprint)

    var home_chunk := world.get_chunk(Vector2i(base_x, base_y))
    Rooms.HOME_BASE._run_context_procedures(world, home_chunk.start)


func _check_for_room_collision(world: World, pos: Vector2i, room: RoomBlueprint) -> bool:
    for _y in room.size.y:
        for _x in room.size.x:
            var chunk := world.get_chunk(pos + Vector2i(_x, _y))
            if not chunk or chunk.type != Type.Chunk.NONE:
                return true
    return false


func _generate_exits(world: World) -> void:
    for room: Room in world.rooms.values():
        var exit_count := RNG.randi_range(1,4)
        var sides_left : Array[Direction] = Direction.get_all(true)#CARDINALS.duplicate()
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

        var dirs := Direction.get_all() #CARDINALS.duplicate()
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
                _walkers.append(Walker.new(world, nbr))
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
                _walkers.append(Walker.new(world, nbr))
                room.open = true

            room.exits[dir] = pos + Vector2i(ox, ry)
            world.get_chunk(pos + Vector2i(ox, ry)).add_edge(dir, Type.Chunk.EXIT)

    return true


func _generate_paths(world: World) -> void:
    while not _walkers.is_empty():
        var alive_walkers : Array[Walker] = []
        for walker in _walkers:
            if walker.walk():
                alive_walkers.append(walker)
        _walkers = alive_walkers

    var dirs := [
        Direction.east,
        Direction.southwest,
        Direction.south,
        Direction.southeast
    ]

    for y in range(1, world.size.y-1):
        for x in range(1, world.size.x-1):
            var chunk := world.get_chunk(Vector2i(x, y))
            for dir in dirs:
                var edge := chunk.get_edge(dir)
                if edge == Type.Chunk.PATH or edge == Type.Chunk.EXIT:
                    var pos := chunk.chunk_position
                    var nbr := world.get_chunk(pos + dir.vector)
                    _draw_path(world, chunk, nbr)


func _draw_path(
        world: World,
        chunk1: World.Chunk,
        chunk2: World.Chunk) -> void:

    # var path_pattern := world.tile_set.get_pattern(1)
    # var path_offset := Vector2i(4,4)

    var path := Util.get_bresenham_line(chunk1.start, chunk2.start)
    var size := path.size()

    var half := Globals.CHUNK_HALF

    for i in size+2:
        if i < size:
            var center := path[i] + half
            var vecs := Util.get_square_around_pos(center, 17)
            for pos in vecs:
                if world.get_tile(pos).type == Type.Tile.VOID:
                    world.set_glyph(pos, Glyph.WALL)
                    world.set_tile_type(pos, Type.Tile.WALL)
                    world.astar.set_point_solid(pos, true)
                    world.mrpas.set_transparent(pos, Type.Tile.WALL)

        if i >= 2:
            # world.set_pattern(path[i-2] + path_offset, path_pattern)
            var center := path[i-2] + half
            var vecs := Util.get_square_around_pos(center, 15, true)
            for pos in vecs:
                if (world.get_glyph(pos).matches(Glyph.WALL) or
                    world.get_glyph(pos).matches(Glyph.NONE)):
                    var choices := [Glyph.GRASS, Glyph.SHRUB]
                    var weights := PackedFloat32Array([1, .01])
                    var idx := RNG.rand_weighted(weights)
                    world.set_glyph(pos, choices[idx])
                    world.set_tile_type(pos, Type.Tile.GRASS)
                    world.astar.set_point_solid(pos, false)
                    world.mrpas.set_transparent(pos, Type.Tile.GRASS)


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


func _generate_enemies(world: World) -> void:
    # Place Spotty Red enemy at specific location for now
    var pos := world.get_chunk(Vector2i(2,1)).center

    world.spawn_entity(SpottyRed, pos)


func _generate_treasure(world: World) -> void:
    var treasure : Treasure
    for n in 3:
        var attempts := 0
        treasure = LargeTreasure.create()
        while attempts < 10:
            var rx := RNG.randi_range(0, world.size.x * Globals.CHUNK_SIZE.x)
            var ry := RNG.randi_range(0, world.size.y * Globals.CHUNK_SIZE.y)
            if not _check_for_entity_collision(world, treasure, Vector2i(rx, ry)):
                world.spawn_entity(LargeTreasure, Vector2i(rx, ry))
            attempts += 1
    treasure.queue_free()

    for n in 5:
        var attempts := 0
        treasure = MediumTreasure.create()
        while attempts < 10:
            var rx := RNG.randi_range(0, world.size.x * Globals.CHUNK_SIZE.x)
            var ry := RNG.randi_range(0, world.size.y * Globals.CHUNK_SIZE.y)
            if not _check_for_entity_collision(world, treasure, Vector2i(rx, ry)):
                world.spawn_entity(MediumTreasure, Vector2i(rx, ry))
                break
            attempts += 1
    treasure.queue_free()

    for n in 10:
        var attempts := 0
        treasure = SmallTreasure.create()
        while attempts < 10:
            var rx := RNG.randi_range(0, world.size.x * Globals.CHUNK_SIZE.x)
            var ry := RNG.randi_range(0, world.size.y * Globals.CHUNK_SIZE.y)
            if not _check_for_entity_collision(world, treasure, Vector2i(rx, ry)):
                world.spawn_entity(SmallTreasure, Vector2i(rx, ry))
                break
            attempts += 1
    treasure.queue_free()


func _check_for_entity_collision(world: World, ent: MultiTileEntity, pos: Vector2i) -> bool:
    for vec: Vector2i in ent.get_used_cells():
        var dpos := vec + pos
        var tile := world.get_tile(dpos)
        if not tile: return true
        var glyph := world.get_glyph(dpos)
        if (not glyph.matches(Glyph.NONE) and
            not glyph.matches(Glyph.GRASS) and
            not glyph.matches(Glyph.SHRUB)):
                return true
        if tile._entities.size() > 1:
            return true
    return false


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
    var world : World
    var connected : bool
    var chunk_position : Vector2i
    var current_chunk : World.Chunk :
        get: return world.get_chunk(chunk_position)

    var stack : Array[Vector2i] = []
    var history := {}

    func _init(_world: World, chunk: World.Chunk, _connected := false) -> void:
        world = _world
        connected = _connected
        chunk_position = chunk.chunk_position
        history[current_chunk] = true
        if connected:
            current_chunk.connected = true

    func walk() -> bool:
        for dir in Direction.get_cardinal(true):
            if current_chunk.edges.has(dir):
                continue

            var nbr := world.get_chunk(chunk_position + dir.vector)
            if nbr.type == Type.Chunk.BORDER or  nbr.has_diagonal_neighbor():
                continue

            if (nbr.get_edge(dir) != Type.Chunk.NONE and
                nbr.get_edge(dir) != Type.Chunk.EXIT and
                nbr.get_edge(dir) != Type.Chunk.PATH):
                    continue

            current_chunk.add_edge(dir, Type.Chunk.PATH)

            if dir.is_diagonal:
                var vec := dir.vector
                world.get_chunk(chunk_position + Vector2i(vec.x, 0)).type = Type.Chunk.DIAGONAL
                world.get_chunk(chunk_position + Vector2i(0, vec.y)).type = Type.Chunk.DIAGONAL

            if nbr.connected:
                return resolve()

            stack.append(chunk_position)
            chunk_position += dir.vector
            history[current_chunk] = true
            if connected:
                current_chunk.connected = true
            return true

        return backtrack()

    func backtrack() -> bool:
        for chunk: World.Chunk in history:
            if chunk.connected:
                return resolve()

        if stack.is_empty(): return false

        chunk_position = stack.pop_back() as Vector2i
        return true

    func resolve() -> bool:
        for chunk: World.Chunk in history:
            chunk.connected = true
        return false
