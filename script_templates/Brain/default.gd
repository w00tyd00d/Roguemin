class_name _CLASS_ extends _BASE_


func _init(ent: Entity) -> void:
    super(ent)
    
    # Each brain should initialize with a(n):
    #   pre-defined [_states] dictionary from States
    #   initial state

    _states = States.entity_name_here
    change_state(States.EntityClass.DEFAULT_STATE)


# Used to change how the brain updates each time a turn is made
func update() -> bool:
    return super()


# Used to change how the brain accumulates energy over time
func add_energy(time_units: int) -> void:
    super(time_units)


# Used to change how the entity handles energy over time.
func add_and_check_energy(time_units := 0) -> bool:
    return super(time_units)
