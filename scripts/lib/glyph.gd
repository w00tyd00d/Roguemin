@tool
class_name Glyph extends RefCounted

## Static glyph database for abstract tileset references.

var source: int
var atlas_pos: Vector2
var alt_tile_id : int


static func get_from(map: TileMapLayer, pos: Vector2i) -> Glyph:
    var src := map.get_cell_source_id(pos)
    var atlas_coords := map.get_cell_atlas_coords(pos)
    var alt_tile := map.get_cell_alternative_tile(pos)
    return Glyph.new(src, atlas_coords, alt_tile)


func _init(src: int, atlas_coords: Vector2, _alt_tile_id := 0) -> void:
    source = src
    atlas_pos = atlas_coords
    alt_tile_id = _alt_tile_id


func matches(glyph: Glyph, fuzzy := false) -> bool:
    if (source != glyph.source or
        atlas_pos != glyph.atlas_pos):
        return false
    
    return fuzzy or alt_tile_id == glyph.alt_tile_id


