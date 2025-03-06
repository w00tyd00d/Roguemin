extends Node

## The class in charge of managing the game's state.

signal force_player_state(state: StringName)

signal ASTAR_TEST(arr: Array[Vector2i])


# HUD Signals

signal update_sun_meter(time: int)

signal display_unit_toggle(val: bool)
signal update_unit_toggle(dict: Dictionary)

signal update_selected_unit(type: Type.Unit)

signal update_squad_count(count: int)
signal update_field_count(count: int)
signal update_total_count(count: int)

signal update_money_value(amount: int)


## Global RNG object.
var RNG := RandomNumberGenerator.new()

## Global reference to the current world object
var world : World

## Global reference to the player object
var player : Player


## The current money value the player has accumulated
var money := 0 :
    set(n):
        money = n
        update_money_value.emit(money)
