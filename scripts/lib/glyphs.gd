@abstract
@tool
class_name Glyphs
extends Object

## Static reference of all the glyphs used in the game.

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

# UI Glyphs

static var WHISTLE_CURSOR := Glyph.new(0, Vector2(24,1), 1)
static var THROW_CURSOR := Glyph.new(0, Vector2(24,1), 2)

# World Glyphs

static var WALL := Glyph.new(0, Vector2(2,0), 1)
static var GRASS := Glyph.new(0, Vector2(19,7), 1)
static var SHRUB := Glyph.new(0, Vector2(3,5), 1)

static var UNIT_SUMMON_TARGET := Glyph.new(0, Vector2(8,3)) # Bullseye

# Entity Glyphs

static var ATTACK_FG := Glyph.new(0, Vector2(0, 0), 1)
static var ATTACK_BG := Glyph.new(2, Vector2(1, 0))

# Unit Glyphs

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
