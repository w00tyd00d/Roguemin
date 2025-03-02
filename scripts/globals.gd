extends Node

## The size of a tile in pixels.
const TILE_SIZE := Vector2i(8,8)

## The size of a chunk in tiles.
const CHUNK_SIZE := Vector2i(23,23)

## List of all the directional input commands
const DIRECTIONAL_INPUTS := [
    &"c_up",
    &"c_down",
    &"c_left",
    &"c_right",
    &"c_upleft",
    &"c_upright",
    &"c_downleft",
    &"c_downright"
]

## List of all the action input commands
const ACTION_INPUTS := [
    &"c_whistle",
    &"c_throw",
    &"c_dismiss",
    &"c_attack",
    &"c_examine",
    &"c_camera",
    &"c_cycle_right",
    &"c_cycle_left",
    &"c_toggle_red",
    &"c_toggle_blue",
    &"c_toggle_yellow",
    &"c_escape",
    &"c_cancel"
]