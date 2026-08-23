class_name Chunk extends DualMapLayer

## A 23x23 cluster of tiles.

## A reference to the world the chunk exists in.
var world : World
## The position of the chunk on the chunk grid.
var chunk_position : Vector2i :
    set(pos):
        chunk_position = pos
        position = pos * Globals.CHUNK_SIZE * Globals.TILE_SIZE

## The assigned type of the chunk.
var type := Type.Chunk.NONE

## The center position of the chunk.
var center : Vector2i
## The upper left corner position of the chunk.
var start : Vector2i
## The lower right corner position of the chunk.
var end : Vector2i

## The room id the chunk is located in, if at all.
var room : World.Room

## Whether or not the chunk is connected on the path.
## Only counts for chunks that are [code]Path[/code] type.
var connected := false
## The dictionary of edges connected with the chunk.
var edges : Dictionary[Vector2i, Type.Edge] = {}

@onready var fog_of_war := $FogOfWar as TileMapLayer


var empty : bool :
    get: return type == Type.Chunk.NONE or type == Type.Chunk.VOID

var valid_path_chunk : bool :
    get: return type == Type.Chunk.NONE or type == Type.Chunk.PATH


static func create() -> Chunk:
    return preload("uid://bn8yhy11tnaek").instantiate()


func _ready() -> void:
    # Add shadow to Fog of War
    for y in Globals.CHUNK_SIZE.y:
        for x in Globals.CHUNK_SIZE.x:
            fog_of_war.set_cell(Vector2i(x,y), 2, Vector2())


func setup(_world: World, pos: Vector2i) -> Chunk:
    world = _world
    chunk_position = pos
    start = pos * Globals.CHUNK_SIZE
    center = start + Globals.CHUNK_HALF
    end = (pos + Vector2i.ONE) * Globals.CHUNK_SIZE - Vector2i.ONE

    name = "Chunk ({0},{1})".format([chunk_position.x, chunk_position.y])

    return self


func add_edge(dir: Direction, _type: Type.Edge) -> void:
    var nbr := get_neighbor(dir)
    edges[dir.vector] = _type
    nbr.edges[dir.opposite.vector] = _type


func remove_edge(dir: Direction) -> void:
    var nbr := get_neighbor(dir)
    edges.erase(dir)
    nbr.edges.erase(dir.opposite)


func get_edge(dir: Direction) -> Type.Edge:
    return edges.get(dir.vector, Type.Edge.NONE)


func has_edge(dir: Direction) -> bool:
    return get_edge(dir) != Type.Edge.NONE


func get_neighbor(dir: Direction) -> Chunk:
    return world.get_chunk(chunk_position + dir.vector)


func reveal_fog_of_war(tile_pos: Vector2i) -> void:
    fog_of_war.set_cell(tile_pos, -1, Vector2i(-1,-1), -1)