@tool
class_name Glyph extends RefCounted

## Static glyph database for abstract tileset references.

# Reset values

static var NONE := Glyph.new(-1, Vector2(-1,-1), -1)
static var BLACK := Glyph.new(2, Vector2())

# Utility values

static var ZERO := Glyph.new(0, Vector2(15,0))
static var ONE := Glyph.new(0, Vector2(16,0))
static var TWO := Glyph.new(0, Vector2(17,0))
static var THREE := Glyph.new(0, Vector2(18,0))
static var FOUR := Glyph.new(0, Vector2(19,0))
static var FIVE := Glyph.new(0, Vector2(20,0))
static var SIX := Glyph.new(0, Vector2(21,0))
static var SEVEN := Glyph.new(0, Vector2(22,0))
static var EIGHT := Glyph.new(0, Vector2(23,0))
static var NINE := Glyph.new(0, Vector2(24,0))

static var NORTH := Glyph.new(0, Vector2(14,1)) # N
static var SOUTH := Glyph.new(0, Vector2(19,1)) # S
static var WEST := Glyph.new(0, Vector2(23,1)) # W
static var EAST := Glyph.new(0, Vector2(5,1)) # E

static var LATCH_POINT := Glyph.new(0, Vector2(4,0)) # %

static var TEST := Glyph.new(0, Vector2(20,1)) # T

# World glyphs

static var WALL := Glyph.new(0, Vector2(2,0), 1)

static var GRASS := Glyph.new(0, Vector2(19,7), 1)
static var SHRUB := Glyph.new(0, Vector2(3,5), 1)

static var UNIT_SUMMON_TARGET := Glyph.new(0, Vector2(8,3)) # Bullseye

# Entity Glyphs

static var ATTACK_FG := Glyph.new(0, Vector2(24, 1), 3)
static var ATTACK_BG := Glyph.new(2, Vector2(1, 0))

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

static var UNIT_GHOST_SMALL := Glyph.new(0, Vector2(17,2), 4)
static var UNIT_GHOST_LARGE := Glyph.new(0, Vector2(16,1), 4)


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


