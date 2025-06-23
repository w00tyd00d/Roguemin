class_name Tile extends RefCounted

## The base class for any tile found within the [World].

const DEFAULT_MAX_VALUE := 2**31-1

## The weakref of the world object this tile is attached to.
var world : World : 
    set(_world):
        _world_ref = weakref(_world)
    get: return _get_world()

## The grid position of the tile.
var grid_position : Vector2i

## The chunk the tile resides in.
var chunk : World.Chunk :
    get: return world.get_chunk(grid_position / Globals.CHUNK_SIZE)

## The type of tile.
var type := Type.Tile.VOID

## Cached indication if this tile is naturally walkable
var walkable := true

## Cached indication whether the tile is inhabited by the player
var has_player := false

## Flag that returns if the cell is currently occupied.
var is_empty : bool :
    get: return (not has_player and # Player is an entity, but we cache with a bool anyway
                not has_units and
                not has_entities)

## Flag that returns whether the cell has (non-unit) Entities in it
var has_entities : bool :
    get: return not _entities.is_empty()

## Flag that returns whether the cell has Units in it
var has_units : bool :
    get: return (not _units[Type.Unit.RED].is_empty() or
                not _units[Type.Unit.YELLOW].is_empty() or
                not _units[Type.Unit.BLUE].is_empty())


## The value of the tile on the world's flow field.
var flow_field_value := DEFAULT_MAX_VALUE

## The cached distance the tile is from any given wall tile._acc
var distance_from_wall := DEFAULT_MAX_VALUE :
    set(num): distance_from_wall = mini(distance_from_wall, num)

## The dictionary of (Pikmin) units within the tile.
var _units : Dictionary[Type.Unit, Dictionary] = {
    Type.Unit.RED: {},
    Type.Unit.YELLOW: {},
    Type.Unit.BLUE: {},
}

## The dictionary of multi-tile entities currently occupying the tile
var _entities : Dictionary[Entity, bool] = {}

## The weakref storage of the world to prevent memory leaks
var _world_ref : WeakRef


func _init(_world: World, grid_pos: Vector2i) -> void:
    world = _world
    grid_position = grid_pos


func get_neighbor(dir: Direction) -> Tile:
    var npos := grid_position + dir.vector
    return world.get_tile(npos)


func get_cardinal_neighbors() -> Array[Tile]:
    if not GameState.is_valid_object(world):
        return []
    
    var res : Array[Tile] = []
    var arr := Direction.get_cardinal(true)
    
    for dir in arr:
        var npos := grid_position + dir.vector
        var tile := _get_world().get_tile(npos)
        if tile: res.append(tile)
    return res


func get_all_neighbors() -> Array[Tile]:
    if not GameState.is_valid_object(_get_world()):
        return []
    
    var res : Array[Tile] = []
    var arr := Direction.get_all(true)
    
    for dir in arr:
        var npos := grid_position + dir.vector
        var tile := _get_world().get_tile(npos)
        if tile: res.append(tile)
    return res


func set_distance_from_wall(num: int) -> bool:
    if num >= distance_from_wall:
        return false
    
    distance_from_wall = num
    return true


func add_entity(ent: Entity) -> void:
    _entities[ent] = true
    if ent is Player:
        has_player = true


func remove_entity(ent: Entity) -> void:
    _entities.erase(ent)
    if ent is Player:
        has_player = false


func has_entity(ent) -> bool:
    return _entities.has(ent)


func get_first_entity() -> MultiTileEntity:
    for ent in _entities.keys():
        if ent is Player: continue
        return ent
    return null


func add_unit(unit: Unit) -> void:
    _units[unit.type][unit] = true


func remove_unit(unit: Unit) -> void:
    _units[unit.type].erase(unit)


func get_units(_type: Type.Unit) -> Array[Unit]:
    return _units[_type].keys()


func get_all_units() -> Array[Unit]:
    var res : Array[Unit] = []
    for dict in _units.values():
        res.append_array((dict.keys()))
    return res


func whistled() -> void:
    var player := GameState.player

    for _type in player.unit_toggle:
        if player.unit_toggle[_type]:
            for unit: Unit in _units[_type]:
                unit.join_squad()


func attacked(dmg: int) -> void:
    if has_player:
        GameState.player.take_damage(dmg)

    for unit in get_all_units():
        unit.die()


func get_flow_field_vector(wall_distance := DEFAULT_MAX_VALUE, include_water := true) -> Vector2i:
    # if _flow_field_vector and wall_distance == DEFAULT_MAX_VALUE and include_water == true:
    #     return _flow_field_vector

    return _get_best_flow_field_vector(wall_distance, include_water)


func _get_world() -> World:
    return _world_ref.get_ref()


func _get_best_flow_field_vector(wall_distance: int, include_water: bool) -> Vector2i:
    const PENALTY := 50
    var vec : Vector2i
    var best := DEFAULT_MAX_VALUE
    # var dist := 0
    for nbr in get_all_neighbors():
        var val := nbr.flow_field_value
        
        if not include_water and nbr.type == Type.Tile.WATER:
            val += PENALTY
        
        # if (wall_distance != DEFAULT_MAX_VALUE and
        #     nbr.distance_from_wall < wall_distance):
        #         val += PENALTY

        if nbr.distance_from_wall < DEFAULT_MAX_VALUE:
            var diff := (8 - nbr.distance_from_wall) * 10
            val += diff
        
        
        if val < best:
            var dir := Direction.by_delta(grid_position, nbr.grid_position)
            vec = dir.vector
            best = val

        
        # if dist < wall_distance and nbr.distance_from_wall > dist:
        #     var dir := Direction.by_delta(grid_position, nbr.grid_position)
        #     vec = dir.vector
        #     best = nbr.flow_field_value
        #     dist = nbr.distance_from_wall
        #     continue
        
        # elif (nbr.flow_field_value < best and
        #     nbr.distance_from_wall >= wall_distance and
        #     (include_water or not include_water and
        #     nbr.type != Type.Tile.WATER)):
        #         var dir := Direction.by_delta(grid_position, nbr.grid_position)
        #         vec = dir.vector
        #         best = nbr.flow_field_value
    return vec
