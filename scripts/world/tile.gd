class_name Tile extends RefCounted

## The base class for any tile found within the [World].



## The world object this tile is attached to.
var world : World

## The grid position of the tile.
var grid_position : Vector2i

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

## The dictionary of (Pikmin) units within the tile.
var _units := {
    Type.Unit.RED: {},
    Type.Unit.YELLOW: {},
    Type.Unit.BLUE: {},
}

## The dictionary of multi-tile entities currently occupying the tile
var _entities := {}

## The value of the tile on the world's flow field.
var _flow_field_value := INF

## The cached direction vector of the most optimal route on the flow field.
var _flow_field_vector : Vector2i

## The cached distance the tile is from any given wall tile._acc
var _distance_from_wall := 2**31-1


func _init(_world: World, grid_pos: Vector2i) -> void:
    world = _world
    grid_position = grid_pos


func get_neighbor(dir: Direction) -> Tile:
    var npos := grid_position + dir.vector
    return world.get_tile(npos)


func get_all_neighbors() -> Array[Tile]:
    var res : Array[Tile] = []
    var arr := Direction.ALL_VECTORS.duplicate()
    arr.shuffle()
    for vec in Direction.ALL_VECTORS:
        var npos := grid_position + vec
        var tile := world.get_tile(npos)
        if tile: res.append(tile)
    return res


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


func _get_best_flow_field_vector(wall_distance := 0, include_water := true) -> Vector2i:
    var vec : Vector2i
    for nbr in get_all_neighbors():
        var best := _flow_field_value
        if (nbr._flow_field_value < best and
            nbr._distance_from_wall >= wall_distance and
            (include_water or not include_water and
            nbr.type != Type.Tile.WATER)):
                var dir := Direction.by_delta(grid_position, nbr.grid_position)
                vec = dir.vector
                best = nbr._flow_field_value
    return vec
