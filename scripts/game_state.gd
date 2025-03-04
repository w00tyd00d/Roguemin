extends Node

## The class in charge of managing the game's state.

signal force_player_state(state: StringName)

signal display_unit_toggle(val: bool)
signal update_unit_toggle(dict: Dictionary)

signal update_unit_count(type: Type.Unit, count: int)

signal update_squad_count(count: int)
signal update_field_count(count: int)
signal update_total_count(count: int)


## Global reference to the current world object
var world : World

## Global reference to the player object
var player : Player