class_name Glyph extends Object

## Static glyph database for abstract tileset references.

var source: int
var atlas_coordinates: Vector2
var alternative_tile_id : int


func _init(src: int, atlas_coords: Vector2, alt_tile_id := 0) -> void:
    source = src
    atlas_coordinates = atlas_coords
    alternative_tile_id = alt_tile_id


func matches(src: int, atlas_coords: Vector2, alt_tile_id := 0) -> bool:
    return (source == src and
            atlas_coordinates == atlas_coords and
            alternative_tile_id == alt_tile_id)