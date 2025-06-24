# class_name World_Old extends DualMapLayer

# ## The game world object. Contains individual tile information as well as
# ## renders the environment.

# ## The built in [AStarGrid2D] pathfinder to the world.
# var astar := AStarTiles.new(self)

# ## The size of the world, in nodes.
# var size : Vector2i :
#     set(vec):
#         size = vec

# ## The dictionary of each [Tile] object populating the world.
# var tiles : Array[Array]

# ## The two-dimensional array of chunks making up the world.
# var chunks : Array[Array]

# ## The collections of chunks in each room, listed by room id.
# var rooms : Dictionary[int, Room] = {}

# ## The amount of time units that have been accumulated so far.
# var time := 0 :
#     set(n):
#         time = n
#         GameState.update_sun_meter.emit(n)

# ## The container node of all of the unit objects in-game
# var unit_container : UnitContainer # injected upon World creation

# ## The number of [Unit] objects currently out on the field.
# var unit_count := 0 :
#     set(n):
#         unit_count = n
#         GameState.update_field_count.emit(n)

# ## The starting position for the player.
# var start_position : Vector2i

# ## The starting tile for the player.
# var start_tile : Tile :
#     get: return get_tile(start_position)

# ## The position of the units' ship.
# var unit_ship_position : Vector2i

# ## The tile of the units' ships
# var unit_ship_tile : Tile :
#     get: return get_tile(unit_ship_position)

# ## The positions from which the player can summon/store units.
# var unit_summon_targets : Array

# ## The position where units will bring salvage back to.
# var salvage_return_position : Vector2i

# ## The position where units will bring salvage back to.
# var salvage_return_tile : Tile :
#     get: return get_tile(salvage_return_position)

# ## The tiles that exist along the center paths between connected chunks
# var salvage_path_tiles : Dictionary[Tile, bool] = {}

# ## The queue (technically stack) of salvage path connections to be ran at world
# ## launch
# var salvage_path_queue : Array[Array] = []

# var mrpas : MRPAS

# ## The [Whistle] object.
# @onready var whistle := $Whistle as Whistle

# ## The throwing cursor.
# @onready var throw_cursor := $ThrowCursor as Node2D

# @onready var fog_of_war := $FogOfWar as TileMapLayer


# static func create() -> World:
#     return preload("uid://12ynotjnohm3").instantiate()


# func _ready() -> void:
#     var _tiles := size * Globals.CHUNK_SIZE
#     mrpas = MRPAS.new(_tiles)
#     for y in _tiles.y:
#         for x in _tiles.x:
#             fog_of_war.set_cell(Vector2i(x,y), 2, Vector2())


# func setup(_size: Vector2i) -> World:
#     size = _size

#     tiles = _create_tiles()
#     chunks = _create_chunks()

#     astar.region = Rect2i(Vector2i(), size * Globals.CHUNK_SIZE)
#     astar.update()

#     return self


# func get_chunk(pos: Vector2i) -> Chunk:
#     if pos.x < 0 or pos.y < 0 or pos.x >= size.x or pos.y >= size.y:
#         return null
#     return chunks[pos.y][pos.x]


# ## Returns a tile object from a given location, returns null if non-existant.
# func get_tile(pos: Vector2i) -> Tile:
#     if not in_bounds(pos):
#         return null
#     return tiles[pos.y][pos.x]


# func get_closest_empty_tiles_at(
#         pos: Vector2i,
#         count: int,
#         include_void := false,
#         include_water := true) -> Array[Tile]:

#     var is_valid := func(tile: Tile):
#         if (not tile or
#             tile.type == Type.Tile.WALL or
#             (not include_void and tile.type == Type.Tile.VOID) or
#             (not include_water and tile.type == Type.Tile.WATER)):
#                 return false
#         return tile.is_empty

#     var start := get_tile(pos)
#     if not start: return []

#     var res : Array[Tile] = []
#     if is_valid.call(start) and count == 1:
#         return [start]

#     var _tiles : Array[Tile] = start.get_all_neighbors()
#     var hist := {start: true}

#     while true:
#         var new_tiles : Array[Tile] = []
#         for tile in _tiles:
#             if hist.has(tile): continue

#             if is_valid.call(tile):
#                 res.append(tile)
#                 if res.size() == count:
#                     return res

#             hist[tile] = true
#             new_tiles.append_array(tile.get_all_neighbors())

#         _tiles = new_tiles

#     return []


# func get_closest_empty_tiles(
#         tile: Tile,
#         count: int,
#         include_void := false,
#         include_water := true) -> Array[Tile]:

#     return get_closest_empty_tiles_at(tile.grid_position, count, include_void, include_water)


# func get_closest_empty_tile_at(
#         pos: Vector2i,
#         include_void := false,
#         include_water := true) -> Tile:

#     return get_closest_empty_tiles_at(pos, 1, include_void, include_water)[0]


# func get_closest_empty_tile(
#         tile: Tile,
#         include_void := false,
#         include_water := true) -> Tile:

#     return get_closest_empty_tiles_at(tile.grid_position, 1, include_void, include_water)[0]


# func set_tile_type(pos: Vector2i, type: Type.Tile) -> void:
#     if not in_bounds(pos): return
#     tiles[pos.y][pos.x].type = type


# func query_tile(tile: Tile) -> Type.Tile:
#     if not tile: return Type.Tile.VOID

#     if not tile.is_empty:
#         return Type.Tile.ENTITY

#     return tile.type


# func query_tile_at(pos: Vector2i) -> Type.Tile:
#     return query_tile(get_tile(pos))


# func move_entity(ent: Entity, dest: Tile) -> void:
#     var tile := ent.current_tile
#     tile.remove_entity(ent)
#     dest.add_entity(ent)


# func move_unit(unit: Unit, dest: Tile) -> void:
#     var tile := unit.current_tile
#     dest.add_unit(unit)
#     tile.remove_unit(unit)


# func spawn_entity(cls, pos: Vector2i) -> void:
#     var entity : Entity = cls.create()
#     entity.grid_position = pos

#     if entity is MultiTileEntity:
#         entity.spawn_position = pos

#     for delta in entity.area_positions:
#         var tile := get_tile(pos + delta)
#         tile.add_entity(entity)

#     add_child(entity)


# func spawn_unit(pos: Vector2i) -> Unit:
#     var type : Type.Unit = [Type.Unit.RED, Type.Unit.YELLOW, Type.Unit.BLUE].pick_random()
#     var unit : Unit = unit_container.get_available_unit()
#     var tile := get_tile(pos)
#     if not unit or not tile: return

#     unit.spawn(pos, type, [true,false].pick_random())
#     tile.add_unit(unit)
#     unit_count += 1
#     return unit


# func in_bounds(vec: Vector2i) -> bool:
#     var x_end := size.x * Globals.CHUNK_SIZE.x
#     var y_end := size.y * Globals.CHUNK_SIZE.y
#     return vec.x >= 0 and vec.y >= 0 and vec.x < x_end and vec.y < y_end


# func add_room(room: Room) -> void:
#     room.id = rooms.size()
#     rooms[room.id] = room


# func queue_salvage_path(start: Vector2i, end: Vector2i) -> void:
#     salvage_path_queue.append([start, end])


# func add_to_salvage_path(start: Vector2i, end: Vector2i) -> void:
#     var line := Geometry2D.bresenham_line(start, end)
#     for pos in line:
#         var tile := get_tile(pos)
#         salvage_path_tiles[tile] = true


# func _create_tiles() -> Array[Array]:
#     var res : Array[Array] = []
#     for y in size.y * Globals.CHUNK_SIZE.y:
#         var row := []
#         for x in size.x * Globals.CHUNK_SIZE.x:
#             row.append(Tile.new(self, Vector2i(x, y)))
#         res.append(row)

#     return res


# func _create_chunks() -> Array[Array]:
#     var res : Array[Array] = []
#     for y in size.y:
#         var row := []
#         for x in size.x:
#             row.append(Chunk.new(self, Vector2i(x, y)))
#         res.append(row)

#     return res


# ## Represents a point on the chunk grid.
# class Chunk:
#     ## A reference to the world the chunk exists in.
#     var world : World
#     ## The position of the chunk on the chunk grid.
#     var chunk_position : Vector2i

#     ## The assigned type of the chunk.
#     var type := Type.Chunk.NONE
#     ## The center position of the chunk.
#     var center : Vector2i
#     ## The upper left corner position of the chunk.
#     var start : Vector2i
#     ## The lower right corner position of the chunk.
#     var end : Vector2i
#     ## The room id the chunk is located in, if at all.
#     var room : Room

#     ## Whether or not the chunk is connected on the path.
#     ## Only counts for chunks that are [code]Path[/code] type.
#     var connected := false
#     ## The dictionary of edges connected with the chunk.
#     var edges : Dictionary[Vector2i, Type.Edge] = {}

#     var empty : bool :
#         get: return type == Type.Chunk.NONE or type == Type.Chunk.VOID

#     var valid_path_chunk : bool :
#         get: return type == Type.Chunk.NONE or type == Type.Chunk.PATH

#     func _init(_world: World, _pos: Vector2i) -> void:
#         world = _world
#         chunk_position = _pos

#         var size := Globals.CHUNK_SIZE
#         var half := Globals.CHUNK_HALF
#         start = _pos * size
#         center = start + half
#         end = (_pos + Vector2i.ONE) * size - Vector2i.ONE

#     func add_edge(dir: Direction, _type: Type.Edge) -> void:
#         var nbr := get_neighbor(dir)
#         edges[dir.vector] = _type
#         nbr.edges[dir.opposite.vector] = _type
#         # print("Adding edge between ", chunk_position, " and ", nbr.chunk_position)

#     func remove_edge(dir: Direction) -> void:
#         var nbr := get_neighbor(dir)
#         edges.erase(dir)
#         nbr.edges.erase(dir.opposite)

#     func get_edge(dir: Direction) -> Type.Edge:
#         return edges.get(dir.vector, Type.Edge.NONE)

#     func has_edge(dir: Direction) -> bool:
#         return get_edge(dir) != Type.Edge.NONE

#     func get_neighbor(dir: Direction) -> World.Chunk:
#         return world.get_chunk(chunk_position + dir.vector)


# class Room:
#     var world : World :
#         set(_world): _world_ref = weakref(_world)
#         get: return _world_ref.get_ref()

#     var blueprint : RoomBlueprint

#     var id : int
#     var size : Vector2i
#     var chunk_position : Vector2i
#     var chunk_area : Array[Chunk]

#     ## The room cluster this room exists in (if one exists)
#     var cluster : Cluster

#     ## Dictionary of exits inside the room, listed by the direction of the exit
#     ## with chunk the exit stems from as a value
#     var exits : Dictionary[Vector2i, Chunk] = {}

#     ## Used as a flag to ensure the room is connected to a path
#     var open := false

#     var _world_ref : WeakRef


#     func _init(
#             _world: World,
#             _blueprint: RoomBlueprint,
#             pos: Vector2i,
#             area: Array[World.Chunk]) -> void:

#         world = _world
#         blueprint = _blueprint
#         size = _blueprint.size
#         chunk_position = pos
#         chunk_area = area

#     func set_exit(dir: Direction, chunk: Chunk) -> void:
#         for exit_chunk: Chunk in exits.values():
#             var start := chunk.center
#             var end := exit_chunk.center
#             world.queue_salvage_path(start, end)

#         exits[dir.vector] = chunk
#         chunk.add_edge(dir, Type.Edge.PATH)

#     func has_exit(dir: Direction) -> bool:
#         return exits.has(dir.vector)

#     func get_exit_chunk(dir: Direction) -> Chunk:
#         return exits.get(dir.vector, null)

#     func run_context_procedures() -> void:
#         var start := chunk_area[0].start
#         blueprint.run_context_procedures(world, start)



# class Cluster:
#     # The representation of adjacent rooms that are directly connected to
#     # each other

#     var rooms : Array[Room] = []
#     var open := false

#     func _init(_rooms: Array[Room]) -> void:
#         rooms = _rooms
#         for room in _rooms:
#             if room.open:
#                 set_open()
#                 break

#     func set_open() -> void:
#         open = true
#         for room in rooms:
#             room.open = true

#     func add(room: Room) -> void:
#         rooms.append(room)
#         if room.open:
#             set_open()

#     func merge(cluster: Cluster) -> void:
#         rooms.append_array(cluster.rooms)
#         if cluster.open:
#             open = true

#         for room in rooms:
#             room.cluster = self
#             room.open = open
