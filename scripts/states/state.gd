class_name State extends RefCounted

# Shorthand for global values
var world : World :
    get: return GameState.world

var player : Player :
    get: return GameState.player

var name := "unknown_state"

## Shorthand for the default cost of an action
var _def_cost : int :
    get: return Globals.DEFAULT_TURN_COST


func enter(_ent: Entity) -> void:
    pass


func exit(_ent: Entity) -> void:
    pass


func get_cost(_ent: Entity) -> int:
    return _def_cost


func can_act(_ent: Entity) -> bool:
    return _ent.brain.energy >= get_cost(_ent)


func use_energy(_ent: Entity) -> void:
    _ent.brain.energy -= get_cost(_ent)


func do_action(_ent: Entity) -> Array:
    # Returns array of values:
    #   [0]: bool, Result of the action
    #   [1]: StringName, OPTIONAL new state
    return [false]


func _mte(ent: Entity) -> MultiTileEntity:
    if ent is MultiTileEntity:
        return ent
    return null


func _enemy(ent: Entity) -> Enemy:
    if ent is Enemy:
        return ent
    return null