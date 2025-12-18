class_name Brain extends RefCounted

## The FSM object that handles an entity's AI. Uses [State] objects.

## The global world object from [GameState].
var world : World :
    get: return GameState.world

## The global world object from [GameState].
var player : Player :
    get: return GameState.player

## Flag for signaling if the entity can act on this turn based on its current
## [State].
var can_act : bool :
    get: return state.can_act(entity)

## The entity this brain is attached to.
var entity : Entity

## The current state of the entity.
var state : State

## The value of time the entity has been synced up to.
var time := 0

## The amount of energy points (time) the entity has accumulated.
var energy := 0

## The state the enemy reverts to when they are killed.
var dead_state := States.dead_state

# The dictionary of states the entity refers to
var _states : Dictionary


func _init(ent: Entity) -> void:
    # Each brain should initialize with:
    #   a pre-defined [_states] dictionary from States
    #   an initial state
    entity = ent


## Returns the name of the current state.
func get_state_name() -> String:
    return state.name


## Resets [member time] and [member energy] back to 0.
func reset() -> void:
    time = 0
    energy = 0


## Resets [member energy] back to 0.
func reset_energy() -> void:
    energy = 0


func die() -> void:
    _assign_state(dead_state)


## Changes the entity's state to a given [States] enum value.[br][br]
## NOTE: This method is agnostic to the enum value that's passed, so make sure
## that you're passing an enum for the appropriate entity!
func change_state(state_id: int) -> void:
    var new_state: State = _states.get(state_id)
    assert(new_state)
    _assign_state(new_state)


## Compares the current state with the given [States] enum value.[br][br]
## NOTE: This method is agnostic to the enum value that's passed, so make sure
## that you're passing an enum for the appropriate entity.
func state_is(id: int) -> bool:
    return state == _states.get(id)


## Updates the brain to the current world time value. Mainly used by the
## [TurnManager] whenever a player takes an action that progresses time.
func update() -> bool:
    var world_time := maxi(time, world.time)
    var time_units := world_time - time

    time = world_time

    return add_and_check_energy(time_units)


## Checks whether the entity can act using [member can_act] and will execute
## the state's [method State.do_action] method if so. Will only add 
## [param time_units] to energy if [member can_act] is not already
## [code]true[/code].
func add_and_check_energy(time_units := 0) -> bool:
    # If we can already act, don't add any more energy
    if can_act:
        return _handle_action()
        
    _add_energy(time_units)

    return _handle_action() if can_act else false


# Virtual method responsible for how [param time_units] are converted to
# energy.
func _add_energy(time_units: int) -> void:
    energy += time_units


func _assign_state(new_state: State) -> void:
    if state:
        state.exit(entity)

    new_state.enter(entity)
    state = new_state


func _handle_action() -> bool:
    var res := state.do_action(entity)

    if res.state != -1:
        change_state(res.state)

    if res.successful or res.energy >= 0:
        state.use_energy(entity, res.energy)
    
    return res.successful
