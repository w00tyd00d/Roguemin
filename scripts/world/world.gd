class_name World extends DualMapLayer

## The game world object. Contains individual tile information as well as
## renders the environment.

## The dictionary of each [Tile] object currently populating the world.
var tiles := {}

## The dictionary of any void tiles currently populating the world. Void tiles
## only exist where there is something populating a void space in the world.
var void_tiles := {}


## Returns a tile object from a given location, returns null if non-existant.
func get_tile(vec: Vector2i) -> Tile:
    if void_tiles.has(vec):
        return void_tiles.get(vec)

    return tiles.get(vec)