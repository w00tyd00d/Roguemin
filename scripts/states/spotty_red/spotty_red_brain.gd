class_name SpottyRedBrain extends Brain


func _init(ent: Entity) -> void:
    super(ent)
    _states = States.spotty_red
    change_state(States.SpottyRed.SLEEP)


# Used to change how the brain updates each time a turn is made
func update() -> bool:
    return super()


# Used to change how the entity accumulates/uses energy over time.
func add_and_check_energy(time_units := 0) -> bool:
    return super(time_units)

