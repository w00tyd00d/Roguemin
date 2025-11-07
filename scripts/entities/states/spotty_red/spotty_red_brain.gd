class_name SpottyRedBrain extends Brain


func _init(ent: Entity) -> void:
    super(ent)

    # Each brain should initialize with a:
    #   pre-defined states dictionary from States
    #   initial current_state member
    _states = States.spotty_red
    change_state(States.SpottyRed.IDLE)



# Used to change how the brain updates each time a turn is made
func update() -> bool:
    return super()


# Used to change how the entity accumulates/uses energy over time.
func add_and_check_energy(time_units: int) -> bool:
    return super(time_units)

