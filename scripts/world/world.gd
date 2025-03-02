class_name World extends DualMapLayer

## The game world object. Contains individual tile information as well as
## renders the environment.

## The size of the world, in nodes.
var size : Vector2i

## The two-dimensional array of chunks making up the world.
var chunks : Array[Array]

## The dictionary of each [Tile] object currently populating the world.
var tiles := {}

## The dictionary of any void tiles currently populating the world. Void tiles
## only exist where there is something populating a void space in the world.
var void_tiles := {}


static func create() -> World:
    return preload("res://prefabs/world.tscn").instantiate()


func setup(_size: Vector2i) -> World:
    size = _size

    var res : Array[Array] = []
    for y in size.y:
        var row := []
        for x in size.x:
            row.append(Chunk.new(Vector2i(x, y)))
        res.append(row)

    chunks = res
    return self


func get_chunk(vec: Vector2i) -> Chunk:
    if vec.x < 0 or vec.y < 0 or vec.x >= size.x or vec.y >= size.y:
        return null
    return chunks[vec.y][vec.x]


## Returns a tile object from a given location, returns null if non-existant.
func get_tile(vec: Vector2i) -> Tile:
    if void_tiles.has(vec):
        return void_tiles.get(vec)

    return tiles.get(vec)


func set_glyph(pos: Vector2i, glyph: Glyph) -> void:
    glyph_layer.set_cell(
        pos,
        glyph.source,
        glyph.atlas_coordinates,
        glyph.alternative_tile_id)


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