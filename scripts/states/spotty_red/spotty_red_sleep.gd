class_name SpottyRedSleep extends State

const DISTURB_RADIUS := 2.0


func _init():
    name = "spotty_red_sleep"


# Changes the rules for when the entity can act
func can_act(_ent: Entity) -> bool:
    return true


func use_energy(ent: Entity, _override := -1) -> void:
    ent.brain.reset_energy()


# Attempts to perform an action to consume energy
func do_action(_ent: Entity) -> ActionResult:
    var ent := _ent as Enemy
    var unit := ent.get_closest_unit(true)

    if not unit:
        return result(false)

    var dist := ent.distance_to(unit.grid_position, true)

    if dist <= DISTURB_RADIUS:
        ent.target_entity = unit
        return result(true).new_state(States.SpottyRed.CHASE)
    
    return result(false)