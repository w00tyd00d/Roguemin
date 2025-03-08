extends Node

# General



## The blink threshold of a blinking icon. (0 - 1000ms)
const GLYPH_BLINK_THRESHOLD := 750

# Geometery

## The size of a tile in pixels.
const TILE_SIZE := Vector2i(8,8)

## The size of a chunk in tiles.
const CHUNK_SIZE := Vector2i(23,23)

## Half the size of a chunk.
const CHUNK_HALF := Vector2i(floori(CHUNK_SIZE.x / 2.0), floori(CHUNK_SIZE.y / 2.0))

## The size of the world in chunks. The outide perimeter of chunks are never
## used and act like a border.
const WORLD_SIZE := Vector2i(12,12)

# Time

## The amount of time units that make up one second.
const TIME_VALUE := 20

## The amount of time units within a single day.
const TIME_LIMIT := (13 * 60 + 30) * TIME_VALUE # 13 min 30 sec

# Controls

## List of all the directional input commands.
const DIRECTIONAL_INPUTS := [
    &"c_wait",
    &"c_up",
    &"c_down",
    &"c_left",
    &"c_right",
    &"c_upleft",
    &"c_upright",
    &"c_downleft",
    &"c_downright",
]

## List of all the action input commands.
const ACTION_INPUTS := [
    &"c_whistle",
    &"c_throw",
    &"c_dismiss",
    &"c_attack",
    &"c_survey",
    &"c_camera",
    &"c_cycle_right",
    &"c_cycle_left",
    &"c_toggle_red",
    &"c_toggle_blue",
    &"c_toggle_yellow",
    &"c_confirm",
    &"k_escape",
    &"c_cancel"
]

## Initial hold time to fire the direction off constantly. (in ms)
const MOVE_HOLD_INITIAL := 0.3

## The time in between subsequent directional calls if the button is held.
const MOVE_HOLD_SUBSEQUENT := 0.12

# Gameplay

## The amount of energy needed to make a turn.
const ENERGY_CAP := 4
## The range at which the player can through the fog of war.
const PLAYER_SIGHT_RANGE := 30
## The range the units can see the unit tether
const UNIT_SIGHT_RANGE := 40

## The range at which the player can reach with a command
const PLAYER_MAX_RANGE := 16

## The minimum size of the whistle
const WHISTLE_MIN_SIZE := 1

## The maximum size of the whistle
const WHISTLE_MAX_SIZE := 4
