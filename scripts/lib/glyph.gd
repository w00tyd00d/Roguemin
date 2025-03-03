class_name Glyph extends RefCounted

## Static glyph database for abstract tileset references.

static var NONE := Glyph.new(-1, Vector2(-1, -1), -1)
static var BLACK := Glyph.new(2, Vector2())

static var WALL := Glyph.new(0, Vector2(2,0), 1)
static var GRASS := Glyph.new(0, Vector2(19, 7), 1)

static var TEST := Glyph.new(0, Vector2(20, 1))

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
    return (source == glyph.source and
            atlas_coordinates == glyph.atlas_coordinates and
            alternative_tile_id == glyph.alternative_tile_id)