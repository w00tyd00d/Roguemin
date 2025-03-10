class_name World extends DualMapLayer

## The game world object. Contains individual tile information as well as
## renders the environment.

## The built in [AStarGrid2D] pathfinder to the world.
var astar := AStar.new(self)

## The size of the world, in nodes.
var size : Vector2i :
    set(vec):
        size = vec

## The dictionary of each [Tile] object populating the world.
var tiles : Array[Array]

## The two-dimensional array of chunks making up the world.
var chunks : Array[Array]

## The collections of chunks in each room, listed by room id.
var rooms := {}

## The amount of time units that have been accumulated so far.
var time := 0 :
    set(n):
        time = n
        GameState.update_sun_meter.emit(n)

## The container node of all of the unit objects in-game
var unit_container : UnitContainer # injected upon World creation

## The number of [Unit] objects currently out on the field.
var unit_count := 0 :
    set(n):
        unit_count = n
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

var mrpas : MRPAS

## The [Whistle] object.
@onready var whistle := $Whistle as Whistle

## The throwing cursor.
@onready var throw_cursor := $ThrowCursor as Node2D

@onready var fog_of_war := $FogOfWar as TileMapLayer


static func create() -> World:
    return preload("res://prefabs/world.tscn").instantiate()


func _ready() -> void:
    var _tiles := size * Globals.CHUNK_SIZE
    mrpas = MRPAS.new(_tiles)
    for y in _tiles.y:
        for x in _tiles.x:
            fog_of_war.set_cell(Vector2i(x,y), 2, Vector2())


func setup(_size: Vector2i) -> World:
    size = _size

    tiles = _create_tiles()
    chunks = _create_chunks()

    astar.region = Rect2i(Vector2i(), size * Globals.CHUNK_SIZE)
    astar.update()

    return self


func get_chunk(vec: Vector2i) -> Chunk:
    if vec.x < 0 or vec.y < 0 or vec.x >= size.x or vec.y >= size.y:
        return null
    return chunks[vec.y][vec.x]


## Returns a tile object from a given location, returns null if non-existant.
func get_tile(pos: Vector2i) -> Tile:
    if not in_bounds(pos):
        return null
    return tiles[pos.y][pos.x]


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

    if not tile.is_empty:
        return Type.Tile.ENTITY

    return tile.type


func query_tile_at(pos: Vector2i) -> Type.Tile:
    return query_tile(get_tile(pos))


func move_entity(ent: Entity, dest: Tile) -> void:
    var tile := ent.current_tile
    tile.remove_entity(ent)
    dest.add_entity(ent)


func move_unit(unit: Unit, dest: Tile) -> void:
    var tile := unit.current_tile
    dest.add_unit(unit)
    tile.remove_unit(unit)


func spawn_entity(cls, pos: Vector2i) -> void:
    var entity : Entity = cls.create()
    entity.grid_position = pos

    if entity is MultiTileEntity:
        entity.spawn_position = pos

    for delta in entity.area_positions:
        var tile := get_tile(pos + delta)
        tile.add_entity(entity)

    add_child(entity)


func spawn_unit(pos: Vector2i) -> Unit:
    var type : Type.Unit = [Type.Unit.RED, Type.Unit.YELLOW, Type.Unit.BLUE].pick_random()
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
            row.append(Chunk.new(self, Vector2i(x, y)))
        res.append(row)

    return res


## Represents a point on the chunk grid.
class Chunk:
    ## A reference to the world the chunk exists in.
    var world : World
    ## The position of the chunk on the chunk grid.
    var chunk_position : Vector2i

    ## The assigned type of the chunk.
    var type := Type.Chunk.NONE
    ## The center tile of the chunk.
    var center : Vector2i
    ## The upper left corner of the chunk.
    var start : Vector2i
    ## The lower right corner of the chunk.
    var end : Vector2i
    ## The room id the chunk is located in, if at all.
    var room : WorldFactory.Room

    ## Whether or not the chunk is connected on the path.
    ## Only counts for chunks that are [code]Path[/code] type.
    var connected := false
    ## The dictionary of edges connected with the chunk.
    var edges := {}

    func _init(_world: World, _pos: Vector2i) -> void:
        world = _world
        chunk_position = _pos

        var size := Globals.CHUNK_SIZE
        var half := Globals.CHUNK_HALF
        start = _pos * size
        center = start + half
        end = (_pos + Vector2i.ONE) * size - Vector2i.ONE

    func add_edge(dir: Direction, _type: Type.Chunk) -> void:
        edges[dir] = _type
        var nbr := world.get_chunk(chunk_position + dir.vector)
        nbr.edges[dir.opposite] = _type

    func get_edge(dir: Direction) -> Type.Chunk:
        return edges.get(dir, Type.Chunk.NONE)

    func has_diagonal_neighbor() -> bool:
        for dir: Direction in edges:
            if not dir.is_diagonal and get_edge(dir) == Type.Chunk.DIAGONAL:
                return true
        return false
