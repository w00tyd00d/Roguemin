class_name State extends RefCounted

# Shorthand for global values
var world : World :
    get: return GameState.world

var player : Player :
    get: return GameState.player


var name := "unknown_state"


func enter(_ent: Entity) -> void:
    pass


func get_cost(_ent: Entity) -> int:
    return Globals.DEFAULT_ENERGY_STEP


func can_act(_ent: Entity) -> bool:
    return _ent.brain.energy >= get_cost(_ent)


func use_energy(_ent: Entity) -> void:
    _ent.brain.energy -= get_cost(_ent)


func do_action(_ent: Entity) -> Array:
    # Returns array of values:
    #   [0]: bool, Result of the action
    #   [1]: StringName, OPTIONAL new state
    return [false]


func exit(_ent: Entity) -> void:
    pass
