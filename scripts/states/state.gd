class_name State extends RefCounted

# Shorthand for global values
var world : World :
    get: return GameState.world

var player : Player :
    get: return GameState.player


var name := "unknown_state"


func enter(_ent: Entity) -> void:
    pass


func do_action(_ent: Entity) -> Array:
    # Returns array of values:
    #   [0]: bool, Result of the action
    #   [1]: StringName, OPTIONAL new state
    return [true]


func exit(_ent: Entity) -> void:
    pass
