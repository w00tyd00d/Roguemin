class_name Brain extends RefCounted

## The global world object from [GameState]
var world : World :
    get: return GameState.world

## The global world object from [GameState]
var player : Player :
    get: return GameState.player

## Flag for signaling if the entity can act on this turn.
var can_act : bool :
    get: return state.can_act(entity)

## The value of time the entity has been synced up to.
var time := 0

## The amount of energy points (time) the entity has accumulated.
var energy := 0

## The entity this brain is attached to
var entity : Entity

## The current state of the entity
var state : State

## The dictionary of states the entity refers to
var _states : Dictionary


func _init(ent: Entity) -> void:
    # Each brain should initialize with a(n):
    #   pre-defined [_states] dictionary from States
    #   initial state
    entity = ent


func reset() -> void:
    time = 0
    energy = 0


func get_state_name() -> String:
    return state.name


func change_state(state_id: int) -> void:
    var new_state : State = _states.get(state_id)
    
    if not new_state:
        print("INVALID STATE ID FOR {0} : ID {1}".format([entity.entity_name, state_id]))
        return
    
    if state:
        state.exit(entity)

    new_state.enter(entity)
    state = new_state


func state_is(id: int) -> bool:
    return state == _states.get(id)


func update() -> bool:
    var world_time := maxi(time, world.time)
    var time_units := world_time - time

    time = world_time

    return add_and_check_energy(time_units)


func add_energy(time_units: int) -> void:
    energy += time_units


func reset_energy() -> void:
    energy = 0


func add_and_check_energy(time_units := 0) -> bool:
    # If we can already act, don't add any more energy
    if can_act:
        return _handle_action()
        
    add_energy(time_units)

    return _handle_action() if can_act else false


func _handle_action() -> bool:
    var res := state.do_action(entity)

    if res.state != -1:
        change_state(res.state)

    if res.success:
        state.use_energy(entity, res.energy)
    
    return res.success
