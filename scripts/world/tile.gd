class_name Tile extends RefCounted

## The base class for any tile found within the [World].

enum Type { VOID, WALL, GRASS, WATER }

## The world object this tile is attached to.
var world : World

## The grid position of the tile.
var grid_position : Vector2i 

## The type of tile.
var type : Type

## Cached indication whether the tile is inhabited by the player
var has_player := false

## The dictionary of (Pikmin) units within the tile.
var _units := {}

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