class_name InanimateBrain extends Brain


func _init(ent: Entity) -> void:
    _states = States.inanimate_states
    change_state(States.Inanimate.DEFAULT)
    super(ent)


# Used to change how the brain updates each time a turn is made
func update() -> bool:
    return super()


# Used to change how the entity accumulates/uses energy over time.
func add_and_check_energy(time_units: int) -> bool:
    if can_act:
        return _handle_action()
    
    var mte := entity as MultiTileEntity
    
    @warning_ignore("integer_division")
    var half_count := mte.latch_point_count / 2

    if mte.carrier_count < half_count:
        action_energy = 0
        return false

    var diff : float = mte.carrier_count - half_count
    var val := diff / mte.latch_point_count

    action_energy += int(val * time_units)

    return _handle_action() if can_act else false