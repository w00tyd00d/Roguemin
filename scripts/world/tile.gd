class_name Tile extends RefCounted

## The base class for any tile found within the [World].



## The world object this tile is attached to.
var world : World

## The grid position of the tile.
var grid_position : Vector2i

## The type of tile.
var type : Type.Tile

## Cached indication whether the tile is inhabited by the player
var has_player := false

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


func _init(_world: World, grid_pos: Vector2i) -> void:
    world = _world
    grid_position = grid_pos


func get_neighbor(dir: Direction) -> Tile:
    var npos := grid_position + dir.vector
    return world.get_tile(npos)


func add_entity(ent: Entity) -> void:
    _entities[ent] = true
    if ent is Player:
        has_player = true


func remove_entity(ent: Entity) -> void:
    _entities.erase(ent)
    if ent is Player:
        has_player = false


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