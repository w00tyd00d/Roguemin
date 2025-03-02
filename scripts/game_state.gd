extends Node

## The class in charge of managing the game's state.

signal force_player_state(state: StringName)

## Global reference to the current world object
var world : World

## Global reference to the player object
var player : Player