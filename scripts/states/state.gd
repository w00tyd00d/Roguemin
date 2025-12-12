class_name State extends RefCounted

# Shorthand for the default cost of an action
const DEFAULT_COST := Globals.DEFAULT_TURN_COST

# Shorthand for global values
var world : World :
    get: return GameState.world

var player : Player :
    get: return GameState.player

var name := "unknown_state"

# Do not call directly, use result(bool) method instead
var _action_result := ActionResult.new()


func enter(_ent: Entity) -> void:
    pass


func exit(_ent: Entity) -> void:
    pass


func get_cost(_ent: Entity) -> int:
    return DEFAULT_COST


func can_act(_ent: Entity) -> bool:
    return _ent.brain.energy >= get_cost(_ent)


func use_energy(_ent: Entity, override := -1) -> void:
    _ent.brain.energy -= override if override >= 0 else get_cost(_ent)


func do_action(_ent: Entity) -> ActionResult:
    return result(false)


# Returns ActionResult object:
#   success: bool, Result of the action
#   override: int, OPTIONAL overridden energy cost
# Chain a .new_state(state) call to include:
#   state: enum, OPTIONAL new state to enter
func result(success: bool, energy_override := -1) -> ActionResult:
    return _action_result.update(success, energy_override)


func _mte(ent: Entity) -> MultiTileEntity:
    if ent is MultiTileEntity:
        return ent
    return null


func _enemy(ent: Entity) -> Enemy:
    if ent is Enemy:
        return ent
    return null


## The results of an action made by the state
class ActionResult:
    var success: bool
    var energy: int
    var state: int

    func update(valid: bool, energy_override: int) -> ActionResult:
        success = valid
        energy = energy_override
        state = -1
        return self

    func new_state(state_enum: int) -> ActionResult:
        state = state_enum
        return self