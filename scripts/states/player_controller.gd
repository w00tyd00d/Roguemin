class_name PlayerController extends Node

var states : Dictionary = {}
var current_state : PlayerState


func _ready() -> void:
    for child: PlayerState in get_children():
        states[child.name.to_lower()] = child
        child.state_changed.connect(change_state)
    
    GameState.force_player_state.connect(change_state)
    InputManager.add(_input_handler)
    
    current_state = states["walk"]


func get_state() -> String:
    return current_state.name


func change_state(state_name: String) -> void:
    if state_name not in states:
        print("ENTERING INVALID STATE : {0}".format([state_name]))
        return
    
    var new_state : PlayerState = states[state_name.to_lower()]
    if current_state:
        current_state.exit()
    
    new_state.enter()
    current_state = new_state


func _input_handler() -> void:
    for inp in Globals.DIRECTIONAL_INPUTS + Globals.ACTION_INPUTS:
        if Input.is_action_just_pressed(inp):
            _update_state(inp)

    
func _update_state(inp: StringName) -> void:
    var res := current_state.update(inp)
    if res[0]: TurnManager.process_turns(res[1])

