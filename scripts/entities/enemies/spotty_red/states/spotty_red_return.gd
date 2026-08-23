class_name SpottyRedReturn extends State

const ROTATE_COST := DEFAULT_COST
const HOME_PROXIMITY := 2


func _init():
    name = "spotty_red_return"


# Changes what the cost of the action will be
func get_cost(_ent: Entity) -> int:
    return SpottyRed.MOVE_SPEED


# Attempts to perform an action to consume energy
func do_action(_ent: Entity) -> ActionResult:
    var ent := _enemy(_ent)
    
    # Try to detect a new threat within a smaller range as we head back
    var target := ent.get_closest_target()

    if target:
        var dist := ent.grid_position.distance_squared_to(target.grid_position)
        var half := ent.sight_range / 2.0

        if dist < half * half:
            ent.target_entity = target
            return result(true).new_state(States.SpottyRed.CHASE)

    # If we're within a proximity of home, go back to sleep
    if ent.distance_to(ent.spawn_position) <= HOME_PROXIMITY:
        return result(true).new_state(States.SpottyRed.SLEEP)

    # Turn in place if aren't facing the direction of home
    if ent.turn_towards(ent.spawn_position):
        return result(true, SpottyRed.ROTATE_SPEED)

    return result(ent.move_towards(ent.spawn_tile))
