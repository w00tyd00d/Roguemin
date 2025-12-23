extends Node

## The global constants used throughout the game.

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

## The default amount of time units incremented per turn
const DEFAULT_TURN_COST := 100

## The amount of time units equal to one second
const TIME_SECOND := DEFAULT_TURN_COST * 5

## The amount of time units within a single day.
const TIME_LIMIT := 13 * 60 * TIME_SECOND # 13 min

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
const MOVE_HOLD_SUBSEQUENT := 0.1

# Gameplay

## The range at which the player can through the fog of war.
const PLAYER_SIGHT_RANGE := 30

## The range at which the player can reach with a command
const PLAYER_MAX_RANGE := 16

## The minimum size of the whistle
const WHISTLE_MIN_SIZE := 1

## The maximum size of the whistle
const WHISTLE_MAX_SIZE := 4

# Units 

const UNIT_DISTANCE_CLOSE := 1.5
const UNIT_DISTANCE_MEDIUM := 8.0
const UNIT_DISTANCE_FAR := 40.0

## The range the units can see the unit tether
const UNIT_SIGHT_RANGE := UNIT_DISTANCE_FAR

var BOID_COHESION_WEIGHT := 1.0
var BOID_ALIGNMENT_WEIGHT := 1.0
var BOID_DESTINATION_WEIGHT := 3.0
# var BOID_AVOIDANCE_WEIGHT := 1.0