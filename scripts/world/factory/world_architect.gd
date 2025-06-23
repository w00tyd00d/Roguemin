class_name WorldArchitect extends RefCounted

## The class responsible for procedurally generating the rooms and paths
## of the world.

const ROOM_PLACE_ATTEMPTS := 10

var RNG := GameState.RNG

# The astar grid to navigate the chunks
var astar : AStarChunks

# Marked chunks to spawn walkers at when ready to make paths (outside of room)
# The bool represents if the walker is connected to the main path or not
var _marked_exit_chunks : Dictionary[World.Chunk, bool] = {}


func run(world: World) -> void:
    generate_infrastructure(world)
    generate_rooms(world)
    generate_exits(world)
    generate_paths(world)


func generate_infrastructure(world: World) -> void:
    # Creates tiles, chunks, and astar map
    world.setup(Globals.WORLD_SIZE)
    astar = AStarChunks.new(world)

    # Reset marked chunks
    _marked_exit_chunks = {}

    # Create a border of void chunks to surround the traversable world
    for _x in world.size.x:
        world.get_chunk(Vector2i(_x, 0)).type = Type.Chunk.VOID
        world.get_chunk(Vector2i(_x, world.size.y-1)).type = Type.Chunk.VOID
    for _y in world.size.y-2:
        world.get_chunk(Vector2i(0, _y+1)).type = Type.Chunk.VOID
        world.get_chunk(Vector2i(world.size.x-1, _y+1)).type = Type.Chunk.VOID


func generate_rooms(world: World) -> void:
    _place_home_base(world)
    _place_world_rooms(world)


func generate_exits(world: World) -> void:
    # Skip the main base room for now
    for i in range(1, world.rooms.size()):
        var room := world.rooms[i]
        var exit_count := RNG.randi_range(1,4) - room.exits.size()
        var sides_left := Direction.get_cardinal(true)

        while exit_count > 0 and sides_left.size() > 0:
            var dir := sides_left[-1]

            assert(not dir.is_diagonal)

            if room.has_exit(dir):
                sides_left.pop_back()
                exit_count -= 1
                continue

            if _establish_exit(world, room, dir):
                exit_count -= 1

            sides_left.pop_back()

    # Double check that we don't have any isolated room clusters
    for room: World.Room in world.rooms.values():
        if room.open: continue
        for dir in room.exits:
            var chunk := room.exits[dir]
            assert(chunk.room)
            if chunk.room.open:
                break

        var dirs := Direction.get_cardinal(true)

        for dir in dirs:
            if room.has_exit(dir): continue
            if _establish_exit(world, room, dir): break


func generate_paths(world: World) -> void:
    # var walkers : Array[Walker] = []

    # Add path edges to declared exits within each room
    # for id in world.rooms:
    #     var room := world.rooms[id]
    #     for vec in room.exits:
    #         var dir := Direction.by_pattern(vec)
    #         var chunk := room.get_exit_chunk(dir)
    #         chunk.add_edge(dir, Type.Edge.PATH)

    # LEFT OFF HERE, THINK HOW TO IMPLEMENT MST USING THE EXITS AS NODES

    # Create list of astar paths from every exit to each other
    var paths : Array[Array] = []
    var size := _marked_exit_chunks.size()
    var chunks : Array[World.Chunk] = _marked_exit_chunks.keys()

    for i in range(size-1):
        for j in range(1, size-i):
            # DEBUG
            # var chunk_pos1 := chunks[i].chunk_position
            # var chunk_pos2 := chunks[i+j].chunk_position

            var path := astar.get_full_path(chunks[i], chunks[i+j])
            if not path.is_empty():
                paths.append(path)

    # Sort the lists of paths by their length, putting the shortest first
    paths.sort_custom(func(a: Array, b: Array) -> bool:
        return a.size() < b.size()
    )

    # Iterate through the paths in sorted order to assign edges, ignoring
    # connections to paths that have both points already connected
    var known_nodes : Dictionary[Vector2i, bool] = {}

    for path: Array[Vector2i] in paths:
        var start := path[0]
        var end := path[-1]

        if known_nodes.has(start) and known_nodes.has(end):
            continue

        known_nodes[start] = true
        known_nodes[end] = true

        # print("Path is ", path)

        for i in path.size()-1:
            var chunk1 := world.get_chunk(path[i])
            var chunk2 := world.get_chunk(path[i+1])
            var dir := Direction.by_delta(path[i], path[i+1])

            chunk1.add_edge(dir, Type.Edge.PATH)

            chunk1.type = Type.Chunk.PATH
            chunk2.type = Type.Chunk.PATH


    # # Spawn the walkers at each of the marked chunks
    # for chunk in _marked_exit_chunks:
    #     var connected := _marked_exit_chunks[chunk]
    #     walkers.append(Walker.new(world, chunk, connected))

    # # Let each walker generate paths
    # while not walkers.is_empty():
    #     var alive_walkers : Array[Walker] = []
    #     for walker in walkers:
    #         if walker.walk():
    #             alive_walkers.append(walker)
    #         else:
    #             walker.active = false
    #     walkers = alive_walkers
    #     print(walkers.size(), " walkers left alive!")

    # Do a scan of the entire field and begin drawing each path each walker
    # have defined
    for y in range(1, world.size.y-1):
        for x in range(1, world.size.x-1):
            var chunk := world.get_chunk(Vector2i(x, y))
            for dir in [Direction.east, Direction.south]:
                var edge := chunk.get_edge(dir)
                var nbr := chunk.get_neighbor(dir)

                # WILL NEED TO HANDLE DYNAMICALLY UPDATING FOR BREAKING WALLS
                if edge != Type.Edge.NONE:
                    var start := chunk.center
                    var end := nbr.center
                    world.queue_salvage_path(start, end)

                if edge == Type.Edge.PATH:
                    _draw_path(world, chunk, nbr)


func _place_home_base(world: World) -> void:
    # Establish the home base room location and four initial exits
    var base_x := RNG.randi_range(2, world.size.x-5)
    var base_y := RNG.randi_range(2, world.size.y-4)

    _place_room(world, Vector2i(base_x, base_y), Rooms.HOME_BASE)
    var base_room := world.rooms[0]
    base_room.open = true

    # HARD CODED EXITS FOR NOW, MAY CHANGE IN THE FUTURE
    var top := world.get_chunk(Vector2i(base_x+1, base_y))
    var lft := world.get_chunk(Vector2i(base_x, base_y+1))
    var bot := world.get_chunk(Vector2i(base_x+1, base_y+1))
    var rgt := world.get_chunk(Vector2i(base_x+2, base_y+1))

    base_room.set_exit(Direction.north, top)
    base_room.set_exit(Direction.west, lft)
    base_room.set_exit(Direction.south, bot)
    base_room.set_exit(Direction.east, rgt)

    _marked_exit_chunks[top.get_neighbor(Direction.north)] = true
    _marked_exit_chunks[lft.get_neighbor(Direction.west)] = true
    _marked_exit_chunks[bot.get_neighbor(Direction.south)] = true
    _marked_exit_chunks[rgt.get_neighbor(Direction.east)] = true


func _place_world_rooms(world: World) -> void:
    var room_total := RNG.randi_range(5,6)
    var room_count := 1 # Home base is already created
    var loops := 0

    while room_count < room_total and loops <= room_total * 2:
        var blueprint := Rooms.pick_random()
        var attempts := 0
        var room_pos := Vector2i()

        while room_pos == Vector2i() and attempts < ROOM_PLACE_ATTEMPTS:
            var rx := RNG.randi_range(1, world.size.x-1)
            var ry := RNG.randi_range(1, world.size.y-1)
            if _check_for_room_collision(world, Vector2i(rx, ry), blueprint):
                attempts += 1
                continue
            room_pos = Vector2i(rx, ry)

        if room_pos == Vector2i():
            continue

        if _place_room(world, room_pos, blueprint):
            room_count += 1

        loops += 1


func _place_room(
        world: World,
        chunk_pos: Vector2i,
        blueprint: RoomBlueprint) -> bool:

    var room := _create_room(world, chunk_pos, blueprint)
    _construct_room(world, chunk_pos, blueprint)

    world.add_room(room)
    room.run_context_procedures()

    return true


func _create_room(world: World, chunk_pos: Vector2i, blueprint: RoomBlueprint) -> World.Room:
    var chunks: Array[World.Chunk] = []
    var room := World.Room.new(world, blueprint, chunk_pos, chunks)

    # Assign the chunks
    for dy in blueprint.size.y:
        for dx in blueprint.size.x:
            var delta := Vector2i(dx, dy)
            var chunk := world.get_chunk(chunk_pos + delta)

            # IF PREFAB ROOM, ATTEMPT TO ALIGN EXIT IF ONE EXISTS
            # IF PROCGEN ROOM, SYNC EXIT CHUNK WITH NEIGHBOR IF ONE EXISTS

            # For now, we treat all rooms as procgen rooms
            if _marked_exit_chunks.has(chunk):
                var vec : Vector2i = chunk.edges.keys()[0]
                var dir := Direction.by_pattern(vec)
                var nbr := chunk.get_neighbor(dir)
                room.set_exit(dir, chunk)

                if nbr.room.cluster:
                    if room.cluster:
                        nbr.room.cluster.merge(room.cluster)
                    else:
                        nbr.room.cluster.add(room)
                else:
                    var cluster := World.Cluster.new([nbr.room, room])
                    room.cluster = cluster
                    nbr.room.cluster = cluster

                _marked_exit_chunks.erase(chunk)

            chunk.type = Type.Chunk.ROOM
            chunk.room = room

            chunks.append(chunk)

    # Update the astar grid
    astar.fill_solid_region(Rect2i(chunk_pos, blueprint.size), true)

    return room


func _check_for_room_collision(world: World, pos: Vector2i, room: RoomBlueprint) -> bool:
    for _y in room.size.y:
        for _x in room.size.x:
            var chunk := world.get_chunk(pos + Vector2i(_x, _y))
            if not chunk or chunk.type != Type.Chunk.NONE:
                return true
    return false


func _construct_room(world: World, chunk_pos: Vector2i, blueprint: RoomBlueprint) -> void:
    # Place down the room tile by tile
    for dpos: Vector2i in blueprint.tile_data:
        var glyph : Glyph = blueprint.tile_data[dpos]
        var tile_pos := world.get_chunk(chunk_pos).start + dpos

        if glyph.matches(Glyph.GRASS):
            var choices := [Glyph.GRASS, Glyph.SHRUB]
            var weights := PackedFloat32Array([1, .01])
            var idx := RNG.rand_weighted(weights)

            glyph = choices[idx]
            world.set_tile_type(tile_pos, Type.Tile.GRASS)
            world.fog_of_war.set_cell(tile_pos, -1, Vector2i(-1,-1), -1)

        else:
            world.set_tile_type(tile_pos, Type.Tile.WALL)
            world.astar.set_point_solid(tile_pos, true)
            world.mrpas.set_transparent(tile_pos, Type.Tile.WALL)

        world.set_glyph(tile_pos, glyph)
        if blueprint is MainBaseBlueprint:
            world.fog_of_war.set_cell(tile_pos, -1, Vector2i(-1,-1), -1)


func _establish_exit(world: World, room: World.Room, dir: Direction) -> bool:
    var x: int
    var y: int
    var dpos: Vector2i

    match dir:
        Direction.north, Direction.south:
            x = RNG.randi_range(0, room.size.x-1)
            y = 0 if dir == Direction.north else room.size.y-1
            dpos = Vector2i(x, dir.vector.y + y)

        Direction.west, Direction.east:
            x = 0 if dir == Direction.west else room.size.x-1
            y = RNG.randi_range(0, room.size.y-1)
            dpos = Vector2i(dir.vector.x + x, y)

    var pos := room.chunk_position
    var nbr := world.get_chunk(pos + dpos)

    match nbr.type:
        Type.Chunk.VOID: return false

        Type.Chunk.ROOM:
            if nbr.room.has_exit(dir.opposite):
                return false
            nbr.room.set_exit(dir.opposite, nbr)

        _:
            nbr.type = Type.Chunk.PATH

            if not _marked_exit_chunks.has(nbr):
                _marked_exit_chunks[nbr] = false

            if room.cluster:
                room.cluster.set_open()
            else:
                room.open = true

    assert(not dir.is_diagonal)

    var exit_chunk = world.get_chunk(pos + Vector2i(x, y))
    room.set_exit(dir, exit_chunk)

    return true


func _draw_path(
        world: World,
        chunk1: World.Chunk,
        chunk2: World.Chunk) -> void:

    # var path_pattern := world.tile_set.get_pattern(1)
    # var path_offset := Vector2i(4,4)

    # var path := Util.get_bresenham_line(chunk1.start, chunk2.start)
    var path := Geometry2D.bresenham_line(chunk1.start, chunk2.start)
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


class Walker:
    var world : World
    var connected : bool
    var chunk_position : Vector2i
    var current_chunk : World.Chunk :
        get: return world.get_chunk(chunk_position)

    var stack : Array[Vector2i] = []
    var history := {}

    var marked_chunks : Dictionary[World.Chunk, WeakRef]
    var active := true

    func _init(
            _world: World,
            chunk: World.Chunk,
            _connected := false,
            _marked_chunks : Dictionary[World.Chunk, WeakRef] = {}) -> void:

        world = _world
        connected = _connected
        marked_chunks = _marked_chunks

        chunk_position = chunk.chunk_position
        history[current_chunk] = true

        if connected:
            current_chunk.connected = true

    func walk() -> bool:
        # assert(not marked_chunks.has(current_chunk))
        if not marked_chunks.has(current_chunk):
            marked_chunks[current_chunk] = weakref(self)

        for dir in Direction.get_all(true):
        # for dir in Direction.get_cardinal(true):
            if current_chunk.get_edge(dir) != Type.Edge.NONE:
                continue

            var nbr := current_chunk.get_neighbor(dir)
            var mark : Walker = marked_chunks.get(nbr, weakref(null)).get_ref()

            if (not nbr.valid_path_chunk or mark == self):
                continue

            # if mark:
            #     print("We found a mark, but it wasn't ours!")

            print(self, ": ", "Neighbor type is: ", nbr.type)

            var adj1 := current_chunk.get_neighbor(dir.adjacent[0])
            var adj2 := current_chunk.get_neighbor(dir.adjacent[1])

            if not (adj1.empty and adj2.empty):
                continue

            if dir.is_diagonal:
                adj1.type = Type.Chunk.VOID
                adj2.type = Type.Chunk.VOID

            assert(nbr.type != Type.Chunk.ROOM)
            current_chunk.add_edge(dir, Type.Edge.PATH)
            nbr.type = Type.Chunk.PATH

            if current_chunk.edges.size() == 4:
                print("Ruh roh Raggy!")

            if nbr.connected or _path_collided(nbr):
                return resolve()

            stack.append(chunk_position)
            chunk_position += dir.vector
            history[current_chunk] = true

            print(self, ": ", "We're walking to ", chunk_position)

            if connected:
                current_chunk.connected = true

            return true

        return backtrack()

    func backtrack() -> bool:
        for chunk: World.Chunk in history:
            if chunk.connected:
                print(self, ": ", "Previous chunk was connected, so")
                return resolve()

        if stack.is_empty():
            print(self, ": ", "Backtracked to the beginning, we're done!")
            return false

        chunk_position = stack.pop_back() as Vector2i
        return true

    func resolve() -> bool:
        print(self, ": ", "We're done!")
        for chunk: World.Chunk in history:
            chunk.connected = true
        return false

    func _path_collided(chunk: World.Chunk) -> bool:
        if not marked_chunks.has(chunk):
            return false

        var walker := marked_chunks[chunk].get_ref() as Walker
        return walker != null and walker != self and walker.active
