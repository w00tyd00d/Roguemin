class_name Tile extends RefCounted

## The base class for any tile found within the [World].

enum Type { VOID, WALL, GRASS, WATER }

var grid_position : Vector2i ## The grid position of the tile.

## The dictionary of (Pikmin) units within the tile.
var units := {}

## The dictionary of multi-tile entities currently occupying the tile
var entities := {}


func _init(grid_pos: Vector2i) -> void:
    grid_position = grid_pos