class_name World extends DualMapLayer

## The game world object. Contains individual tile information as well as
## renders the environment.

## The built in [AStarGrid2D] pathfinder to the world.
var astar := AStar.new(self)

## The size of the world, in nodes.
var size : Vector2i

## The dictionary of each [Tile] object populating the world.
var tiles : Array[Array]

## The two-dimensional array of chunks making up the world.
var chunks : Array[Array]

## The amount of time_units that have been accumulated so far.[br]
## 4 units == 1 second
var time := 0

## The container node of all of the unit objects in-game
var unit_container : UnitContainer # injected upon World creation

## The number of [Unit] objects currently out on the field.
var unit_count := 0

## The [Whistle] object.
@onready var whistle := $Whistle as Whistle

## The throwing cursor.
@onready var throw_cursor := $ThrowCursor as Node2D


static func create() -> World:
    return preload("res://prefabs/world.tscn").instantiate()


func setup(_size: Vector2i) -> World:
    size = _size

    tiles = _create_tiles()
    chunks = _create_chunks()

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


func get_closest_empty_tile(pos: Vector2i) -> Tile:
    var start := get_tile(pos)
    if start.is_empty: return start
    
    var _tiles : Array[Tile] = start.get_all_neighbors()
    var hist := {start: true}
    
    while true:
        var new_tiles : Array[Tile] = []
        for tile in _tiles:
            if hist.has(tile): continue
            
            if tile.is_empty:
                return tile

            hist[tile] = true
            new_tiles.append_array(tile.get_all_neighbors())
        
        _tiles = new_tiles
    
    return null
        

func set_tile_type(pos: Vector2i, type: Type.Tile) -> void:
    if not in_bounds(pos): return
    tiles[pos.y][pos.x].type = type


func query_tile(tile: Tile) -> Type.Tile:
    if not tile: return Type.Tile.VOID

    # BAD SYSTEM, SHOULD REPLACE WITH DATA DRIVEN APPROACH
    var glyph := get_glyph(tile.grid_position)

    if tile.has_units or tile.has_player: return Type.Tile.ENTITY
    if glyph.matches(Glyph.WALL): return Type.Tile.WALL
    if glyph.matches(Glyph.GRASS): return Type.Tile.GRASS

    return Type.Tile.VOID


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
    add_child(entity)
    entity.grid_position = pos


func spawn_unit(pos: Vector2i) -> void:
    var type : Type.Unit = [Type.Unit.RED, Type.Unit.YELLOW, Type.Unit.BLUE].pick_random()
    var unit : Unit = unit_container.get_available_unit()
    var tile := get_tile(pos)
    if not unit or not tile: return
    
    unit.spawn(pos, type, [true,false].pick_random())
    tile.add_unit(unit)


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
            row.append(Chunk.new(Vector2i(x, y)))
        res.append(row)

    return res


## Represents a point on the chunk grid.
class Chunk:
    enum EdgeType { NONE, PATH, EXIT, WALL, ROOM }

    ## A reference to the world the chunk exists in.
    var world : World
    ## The position of the chunk on the chunk grid.
    var chunk_position

    ## The center tile of the chunk
    var center : Vector2i
    ## The upper left corner of the chunk
    var start : Vector2i
    ## The lower right corner of the chunk
    var end : Vector2i

    ## The dictionary of edges connected with the chunk.
    var _edges := {}

    func _init(_pos: Vector2i) -> void:
        chunk_position = _pos

        var size := Globals.CHUNK_SIZE
        var half := Vector2i(floori(size.x / 2.0), floori(size.y / 2.0))
        start = _pos * size
        center = start + half
        end = (_pos + Vector2i.ONE) * size - Vector2i.ONE

    func add_edge(dir: Direction, type: EdgeType) -> void:
        _edges[dir] = type

    func get_edge(dir: Direction) -> EdgeType:
        return _edges.get(dir, EdgeType.NONE)
