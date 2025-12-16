class_name State extends Object

## A flyweight state object. Used by [Brain] and stored within [States].

## Shorthand for [member Globals.DEFAULT_TURN_COST]
## ie: the default cost of an action.
const DEFAULT_COST := Globals.DEFAULT_TURN_COST

# Do not use directly, use result(bool) method instead
static var action_result := ActionResult.new()

## The global world object.
var world : World :
    get: return GameState.world

## The global player object.
var player : Player :
    get: return GameState.player

## The name of the state.
var name := "unknown_state"


## The virtual method that's called when the state is first entered into.
func enter(_ent: Entity) -> void:
    pass


## The virtual method that's called as the state is being exited.
func exit(_ent: Entity) -> void:
    pass


## The virtual method that returns the default cost of the state's action.
## Generally considered the default speed of the entity, ie: higher costs
## mean slower acting entities.
func get_cost(_ent: Entity) -> int:
    return DEFAULT_COST


## The virtual method that returns whether or not the entity can currently act.
## Generally compares the value returned [method get_cost] of the entity with,
## the entity's current energy, but can be used to manipulate when the entity
## can/can't act under other circumstances.
func can_act(_ent: Entity) -> bool:
    return _ent.brain.energy >= get_cost(_ent)


## The virtual method called when a successful action has been triggered.
## Normally it consumes the amount returned by [method get_cost] from the
## entity's energy, but can be manipulated to change how energy is consumed.
## Will also be passed an [param override] value provided by [method result],
## which will completely override the cost.
func use_energy(_ent: Entity, override := -1) -> void:
    _ent.brain.energy -= override if override >= 0 else get_cost(_ent)


## The virtual method responsible for executing the action of the state.
## When the entity is able to act, this is the method that's called and will
## determine what the entity will do. Will always return a [method result]
## method call that will return an [State.ActionResult] to the entity's [Brain].
func do_action(_ent: Entity) -> ActionResult:
    return result(false)


## The method responsible for reporting back the results of an action.
## Used by [method do_action] to report back to the entity's [Brain] if the
## action was a success or not. Can also provide an additional
## [param energy_override] value that will override the amount of energy used
## by the action. (Will only work with values >= 0.)[br][br]
##
## [method result] can also be chained with a [code].new_state()[/code]
## call in order to change the state as a result of the action.
func result(success: bool, energy_override := -1) -> ActionResult:
    return State.action_result.update(success, energy_override)


func _unit(ent: Entity) -> Unit:
    assert(ent is Unit)
    return ent


func _mte(ent: Entity) -> MultiTileEntity:
    assert(ent is MultiTileEntity)
    return ent


func _enemy(ent: Entity) -> Enemy:
    assert(ent is Enemy)
    return ent


## A singleton object that reflects the results of an action made by a
## state.
##
## NOTE: Should not be called directly. Use [method State.result] instead.
class ActionResult extends Object:
    var success: bool ## Whether the action executed. Determines if energy should be drained.
    var energy: int ## The overridden energy cost of the action, if any.
    var state: int ## The new state that should be entered due to the action, if any.

    ## Updates the internals of the object and returns itself.
    ## This is how the object should be referenced instead of referencing it
    ## directly to ensure any residual state is cleansed.
    func update(valid: bool, energy_override: int) -> ActionResult:
        success = valid
        energy = energy_override
        state = -1
        return self

    ## Used to chain together with a previous update call to add a new state
    ## to the result. See [method State.result].[br][br]
    ## NOTE: This method is agnostic to the enum value that's passed, so
    ## make sure that you're passing an enum for the appropriate entity!
    func new_state(state_enum: int) -> ActionResult:
        state = state_enum
        return self