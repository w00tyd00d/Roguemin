class_name World extends Node2D

## The game world object. Contains individual tile information as well as
## renders the environment.

## The built in [AStarGrid2D] pathfinder to the world.
var astar := AStarTiles.new(self)

## The size of the world, in chunks.
var size : Vector2i :
    set(vec):
        size = vec

## The dictionary of each [Tile] object populating the world.
var tiles : Array[Array]

## The two-dimensional array of chunks making up the world.
var chunks : Array[Array]

## The collections of chunks in each room, listed by room id.
var rooms : Dictionary[int, Room] = {}

## The amount of time units that have been accumulated so far.
var time := 0 :
    set(n):
        time = n
        GameState.world_time_changed.emit(n)

## The container node of all of the unit objects in-game
var unit_container : UnitContainer # injected upon World creation

## The number of [Unit] objects currently out on the field.
var unit_count := 0 :
    set(n):
        unit_count = maxi(n, 0)
        GameState.update_field_count.emit(n)

## The starting position for the player.
var start_position : Vector2i

## The starting tile for the player.
var start_tile : Tile :
    get: return get_tile(start_position)

## The position of the units' ship.
var unit_ship_position : Vector2i

## The tile of the units' ships
var unit_ship_tile : Tile :
    get: return get_tile(unit_ship_position)

## The positions from which the player can summon/store units.
var unit_summon_targets : Array

## The position where units will bring salvage back to.
var salvage_return_position : Vector2i

## The position where units will bring salvage back to.
var salvage_return_tile : Tile :
    get: return get_tile(salvage_return_position)

## The tiles that exist along the center paths between connected chunks
var salvage_path_tiles : Dictionary[Tile, bool] = {}

## The queue (technically stack) of salvage path connections to be ran at world
## launch
var salvage_path_queue : Array[Array] = []

var mrpas : MRPAS

## The node the chunks will be a child of for organization purposes
@onready var chunks_node := $Chunks as Node2D

## The node the chunks will be a child of for organization purposes
@onready var treasure_node := $Treasures as Node2D

## The node the chunks will be a child of for organization purposes
@onready var enemies_node := $Enemies as Node2D

## The [Whistle] object.
@onready var whistle := $Whistle as Whistle

## The throwing cursor.
@onready var throw_cursor := $ThrowCursor as Node2D

# @onready var fog_of_war := $FogOfWar as TileMapLayer


static func create() -> World:
    return preload("uid://dl53ytlod4w2y").instantiate()


func _ready() -> void:
    var _tiles := size * Globals.CHUNK_SIZE
    mrpas = MRPAS.new(self, _tiles)


func setup(_size: Vector2i) -> World:
    size = _size

    tiles = _create_tiles()
    chunks = _create_chunks()

    astar.region = Rect2i(Vector2i(), size * Globals.CHUNK_SIZE)
    astar.update()

    return self


func get_chunk(chunk_pos: Vector2i) -> Chunk:
    if chunk_pos.x < 0 or chunk_pos.y < 0 or chunk_pos.x >= size.x or chunk_pos.y >= size.y:
        return null
    return chunks[chunk_pos.y][chunk_pos.x]


## Returns a tile object from a given location, returns null if non-existant.
func get_tile(grid_pos: Vector2i) -> Tile:
    if not in_bounds(grid_pos):
        return null
    return tiles[grid_pos.y][grid_pos.x]


func set_glyph(grid_pos: Vector2i, glyph: Glyph) -> void:
    var chunk_pos := grid_pos / Globals.CHUNK_SIZE
    var tile_pos := grid_pos % Globals.CHUNK_SIZE

    get_chunk(chunk_pos).set_glyph(tile_pos, glyph)


func get_glyph(grid_pos: Vector2i) -> Glyph:
    var chunk_pos := grid_pos / Globals.CHUNK_SIZE
    var tile_pos := grid_pos % Globals.CHUNK_SIZE

    return get_chunk(chunk_pos).get_glyph(tile_pos)


func set_background(grid_pos: Vector2i, glyph: Glyph):
    var chunk_pos := grid_pos / Globals.CHUNK_SIZE
    var tile_pos := grid_pos % Globals.CHUNK_SIZE

    get_chunk(chunk_pos).set_background(tile_pos, glyph)


func get_background(grid_pos: Vector2i):
    var chunk_pos := grid_pos / Globals.CHUNK_SIZE
    var tile_pos := grid_pos % Globals.CHUNK_SIZE

    return get_chunk(chunk_pos).get_background(tile_pos)


func update_fog_of_war(grid_pos: Vector2i, _range: int) -> void:
    mrpas.compute_field_of_view(grid_pos, _range)


func reveal_fog_of_war(grid_pos: Vector2i) -> void:
    var chunk_pos := grid_pos / Globals.CHUNK_SIZE
    var tile_pos := grid_pos % Globals.CHUNK_SIZE

    return get_chunk(chunk_pos).reveal_fog_of_war(tile_pos)



func get_closest_empty_tiles_at(
        pos: Vector2i,
        count: int,
        include_void := false,
        include_water := true) -> Array[Tile]:

    var is_valid := func(tile: Tile):
        if (not tile or
            tile.type == Type.Tile.WALL or
            (not include_void and tile.type == Type.Tile.VOID) or
            (not include_water and tile.type == Type.Tile.WATER)):
                return false
        return tile.is_empty

    var start := get_tile(pos)
    if not start: return []

    var res : Array[Tile] = []
    if is_valid.call(start) and count == 1:
        return [start]

    var _tiles : Array[Tile] = start.get_all_neighbors()
    var hist := {start: true}

    while true:
        var new_tiles : Array[Tile] = []
        for tile in _tiles:
            if hist.has(tile): continue

            if is_valid.call(tile):
                res.append(tile)
                if res.size() == count:
                    return res

            hist[tile] = true
            new_tiles.append_array(tile.get_all_neighbors())

        _tiles = new_tiles

    return []


func get_closest_empty_tiles(
        tile: Tile,
        count: int,
        include_void := false,
        include_water := true) -> Array[Tile]:

    return get_closest_empty_tiles_at(tile.grid_position, count, include_void, include_water)


func get_closest_empty_tile_at(
        pos: Vector2i,
        include_void := false,
        include_water := true) -> Tile:

    return get_closest_empty_tiles_at(pos, 1, include_void, include_water)[0]


func get_closest_empty_tile(
        tile: Tile,
        include_void := false,
        include_water := true) -> Tile:

    return get_closest_empty_tiles_at(tile.grid_position, 1, include_void, include_water)[0]


func set_tile_type(pos: Vector2i, type: Type.Tile) -> void:
    if not in_bounds(pos): return
    tiles[pos.y][pos.x].type = type


func query_tile(tile: Tile) -> Type.Tile:
    if not tile: return Type.Tile.VOID

    if tile.has_entities:
        return Type.Tile.ENTITY

    if tile.has_units:
        return Type.Tile.UNIT

    return tile.type


func query_tile_at(pos: Vector2i) -> Type.Tile:
    return query_tile(get_tile(pos))


func move_entity(ent: Entity, dest: Tile) -> void:
    if ent is MultiTileEntity:
        var world := ent.world
        var area := ent.area_positions as Array[Vector2i]

        for pos in area:
            var dpos := ent.grid_position + pos
            var tile := world.get_tile(dpos)
            if tile: tile.remove_entity(ent)
            world.astar.set_point_weight_scale(dpos, 1)

        for pos in area:
            var dpos := dest.grid_position + pos
            var tile := world.get_tile(dpos)
            tile.add_entity(ent)
            world.astar.set_point_weight_scale(dpos, INF)

        for unit: Unit in ent.carriers:
            var pos : Vector2i = ent.carriers[unit]
            var tile := world.get_tile(dest.grid_position + pos)
            unit.move_to(tile)
    else:
        var tile := ent.current_tile
        tile.remove_entity(ent)
        dest.add_entity(ent)

    ent.last_position = ent.grid_position
    ent.grid_position = dest.grid_position


func move_unit(unit: Unit, dest: Tile) -> void:
    var tile := unit.current_tile

    tile.remove_unit(unit)
    dest.add_unit(unit)

    unit.last_position = unit.grid_position
    unit.grid_position = dest.grid_position


func spawn_entity(cls: GDScript, pos: Vector2i) -> void:
    var entity : MultiTileEntity = cls.create()
    entity.grid_position = pos

    if entity is MultiTileEntity:
        entity.spawn_position = pos

    for delta: Vector2i in entity.area_positions:
        var dpos := pos + delta
        var tile := get_tile(dpos)
        tile.add_entity(entity)
        # MIGHT NEED TO MAKE A GRADIENT INSTEAD OF JUST INF
        astar.set_point_weight_scale(dpos, INF)

    if entity is Treasure:
        treasure_node.add_child(entity, true)
    elif entity is Enemy:
        enemies_node.add_child(entity, true)


func spawn_unit(
        pos: Vector2i,
        type := Type.Unit.NONE) -> Unit:

    if type == Type.Unit.NONE:
        type = [Type.Unit.RED, Type.Unit.YELLOW, Type.Unit.BLUE].pick_random()

    var unit : Unit = unit_container.get_available_unit()
    var tile := get_tile(pos)
    if not unit or not tile: return

    unit.spawn(pos, type, [true,false].pick_random())
    tile.add_unit(unit)
    unit_count += 1
    return unit


func in_bounds(vec: Vector2i) -> bool:
    var x_end := size.x * Globals.CHUNK_SIZE.x
    var y_end := size.y * Globals.CHUNK_SIZE.y
    return vec.x >= 0 and vec.y >= 0 and vec.x < x_end and vec.y < y_end


func add_room(room: Room) -> void:
    room.id = rooms.size()
    rooms[room.id] = room


func queue_salvage_path(start: Vector2i, end: Vector2i) -> void:
    salvage_path_queue.append([start, end])


func add_to_salvage_path(start: Vector2i, end: Vector2i) -> void:
    var line := Geometry2D.bresenham_line(start, end)
    for pos in line:
        var tile := get_tile(pos)
        salvage_path_tiles[tile] = true


func _create_tiles() -> Array[Array]:
    var res : Array[Array] = []
    for y in size.y * Globals.CHUNK_SIZE.y:
        var row := []
        for x in size.x * Globals.CHUNK_SIZE.x:
            row.append(Tile.new(self, Vector2i(x, y)))
        res.append(row)

    return res


func _create_chunks() -> Array[Array]:
    var res : Array[Array] = []
    for y in size.y:
        var row := []
        for x in size.x:
            var chunk := Chunk.create().setup(self, Vector2i(x,y))
            chunks_node.add_child(chunk)
            row.append(chunk)
        res.append(row)

    return res


class Room:
    var world : World :
        set(_world): _world_ref = weakref(_world)
        get: return _world_ref.get_ref()

    var blueprint : RoomBlueprint

    var id : int
    var size : Vector2i
    var chunk_position : Vector2i
    var chunk_area : Array[Chunk]

    ## The room cluster this room exists in (if one exists)
    var cluster : Cluster

    ## Dictionary of exits inside the room, listed by the direction of the exit
    ## with chunk the exit stems from as a value
    var exits : Dictionary[Vector2i, Chunk] = {}

    ## Used as a flag to ensure the room is connected to a path
    var open := false

    var _world_ref : WeakRef


    func _init(
            _world: World,
            _blueprint: RoomBlueprint,
            pos: Vector2i,
            area: Array[Chunk]) -> void:

        world = _world
        blueprint = _blueprint
        size = _blueprint.size
        chunk_position = pos
        chunk_area = area

    func set_exit(dir: Direction, chunk: Chunk) -> void:
        for exit_chunk: Chunk in exits.values():
            var start := chunk.center
            var end := exit_chunk.center
            world.queue_salvage_path(start, end)

        exits[dir.vector] = chunk
        chunk.add_edge(dir, Type.Edge.PATH)

    func has_exit(dir: Direction) -> bool:
        return exits.has(dir.vector)

    func get_exit_chunk(dir: Direction) -> Chunk:
        return exits.get(dir.vector, null)

    func run_context_procedures() -> void:
        var start := chunk_area[0].start
        blueprint.run_context_procedures(world, start)


class Cluster:
    # The representation of adjacent rooms that are directly connected to
    # each other

    var rooms : Array[Room] = []
    var open := false

    func _init(_rooms: Array[Room]) -> void:
        rooms = _rooms
        for room in _rooms:
            if room.open:
                set_open()
                break

    func set_open() -> void:
        open = true
        for room in rooms:
            room.open = true

    func add(room: Room) -> void:
        rooms.append(room)
        if room.open:
            set_open()

    func merge(cluster: Cluster) -> void:
        rooms.append_array(cluster.rooms)
        if cluster.open:
            open = true

        for room in rooms:
            room.cluster = self
            room.open = open
