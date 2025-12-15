class_name SpottyRedWakeUp extends State


func _init():
    name = "spotty_red_wake_up"


func get_cost(_ent: Entity) -> int:
    return DEFAULT_COST * 3


func do_action(_ent: Entity) -> ActionResult:
    var ent := _enemy(_ent)
    var pos := ent.grid_position
    # var unit := GameState.unit_manager.get_closest_unit_to(pos)
    var unit := ent.get_closest_target()

    ent.target_entity = unit
    
    return result(true).new_state(States.SpottyRed.CHASE)

