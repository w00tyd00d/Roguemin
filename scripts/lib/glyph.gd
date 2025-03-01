class_name Glyph extends RefCounted

## Static glyph database for abstract tileset references.

# static var GRASS := Glyph.new()

var source: int
var atlas_coordinates: Vector2
var alternative_tile_id : int


func _init(src: int, atlas_coords: Vector2, alt_tile_id := 0) -> void:
    source = src
    atlas_coordinates = atlas_coords
    alternative_tile_id = alt_tile_id


static func get_from(map: TileMapLayer, pos: Vector2i) -> Glyph:
    var src := map.get_cell_source_id(pos)
    var atlas_coords := map.get_cell_atlas_coords(pos)
    var alt_tile := map.get_cell_alternative_tile(pos)
    return Glyph.new(src, atlas_coords, alt_tile)


func matches(glyph: Glyph) -> bool:
    return (source == glyph.src and
            atlas_coordinates == glyph.atlas_coords and
            alternative_tile_id == glyph.alt_tile_id)