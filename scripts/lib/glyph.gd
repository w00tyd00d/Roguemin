class_name Glyph extends RefCounted

## Static glyph database for abstract tileset references.

static var NONE := Glyph.new(-1, Vector2(-1,-1), -1)
static var BLACK := Glyph.new(2, Vector2())

static var WALL := Glyph.new(0, Vector2(2,0), 1)

static var GRASS := Glyph.new(0, Vector2(19,7), 1)
static var SHRUB := Glyph.new(0, Vector2(3,5), 1)

static var TEST := Glyph.new(0, Vector2(20,1))

static var UNIT_SUMMON_TARGET := Glyph.new(0, Vector2(8,3))

static var UNIT_RED_SMALL := Glyph.new(0, Vector2(17,2), 1)
static var UNIT_YELLOW_SMALL := Glyph.new(0, Vector2(17,2), 2)
static var UNIT_BLUE_SMALL := Glyph.new(0, Vector2(17,2), 3)

static var UNIT_RED_LARGE := Glyph.new(0, Vector2(16,1), 1)
static var UNIT_YELLOW_LARGE := Glyph.new(0, Vector2(16,1), 2)
static var UNIT_BLUE_LARGE := Glyph.new(0, Vector2(16,1), 3)

static var UNIT_RED_SMALL_IDLE := Glyph.new(0, Vector2(17,2), 5)
static var UNIT_YELLOW_SMALL_IDLE := Glyph.new(0, Vector2(17,2), 6)
static var UNIT_BLUE_SMALL_IDLE := Glyph.new(0, Vector2(17,2), 7)

static var UNIT_RED_LARGE_IDLE := Glyph.new(0, Vector2(16,1), 5)
static var UNIT_YELLOW_LARGE_IDLE := Glyph.new(0, Vector2(16,1), 6)
static var UNIT_BLUE_LARGE_IDLE := Glyph.new(0, Vector2(16,1), 7)

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


func get_context_id() -> int:
    var vec := Vector2i(atlas_coordinates)
    if vec.y == 0 and vec.x >= 15 and vec.x <= 24:
        return vec.x - 15
    return -1