class_name MultiTileBrain extends Brain

var mte : MultiTileEntity :
    get: return entity

var is_inanimate : bool :
    get: return state == States.inanimate_state


func add_energy(time_units: int) -> void:
    if is_inanimate:
        return _do_hauling_check(time_units)
    
    super(time_units)


func _do_hauling_check(time_units: int) -> void:
    if can_act: return 
    
    @warning_ignore("integer_division")
    var half_count := mte.latch_point_count / 2

    if mte.carrier_count < half_count:
        reset_energy()

    var diff : float = mte.carrier_count - half_count
    var val := diff / mte.latch_point_count

    action_energy += int(val * time_units)
