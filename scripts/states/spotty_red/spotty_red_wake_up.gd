class_name SpottyRedWakeUp extends State


func _init():
    name = "spotty_red_wake_up"


func get_cost(_ent: Entity) -> int:
    return SpottyRed.MOVE_SPEED


func do_action(_ent: Entity) -> ActionResult:
    var ent := _enemy(_ent)
    var target := ent.get_closest_target()

    if not target:
        return result(true).new_state(States.SpottyRed.SLEEP)

    ent.target_entity = target

    return result(true).new_state(States.SpottyRed.CHASE)
