class_name PlayerState extends Node

signal state_changed(state: String)


var active_state := false


func _ready() -> void:
	pass


func enter() -> void:
	active_state = true


## Runs the current input through the state and updates it accordingly. The
## state will return an array that will relay two bits of information.
## Result[0] will be a boolean as to whether Result[1] is applied or not, and
## Result[1] is the speed modifier of the turn the action consumes.
func update(_inp: StringName) -> Array:
	return [false, 0]


func exit() -> void:
	active_state = false


func _in_range(pos: Vector2i) -> bool:
	var dist := Util.chebyshev_distance(GameState.player.grid_position, pos)
	return dist <= Globals.PLAYER_MAX_RANGE