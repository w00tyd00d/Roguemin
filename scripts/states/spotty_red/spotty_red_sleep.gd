class_name SpottyRedSleep extends State

const DISTURB_RADIUS := 2.0


func _init():
    name = "spotty_red_sleep"


# Called when entering the state
# func enter(ent: Entity) -> void:
#     super(ent)


# Changes what the cost of the action will be
# func get_cost(ent: Entity) -> int:
#     return super(ent)


# Changes the rules for when the entity can act
func can_act(_ent: Entity) -> bool:
    return true


# Changes how energy is consumed from the entity
func use_energy(ent: Entity) -> void:
    ent.brain.reset_energy()


# Attempts to perform an action to consume energy
func do_action(_ent: Entity) -> Array:
    var ent := _ent as Enemy
    var mgr := GameState.unit_manager
    var unit := mgr.get_closest_unit_to(ent.grid_position, true)

    if not unit:
        return [false]

    var dist := ent.distance_to(unit.grid_position, true)

    if dist <= DISTURB_RADIUS:
        ent.target_entity = unit
        return [true, States.SpottyRed.CHASE]
    
    return [false]


# Called when leaving the state
# func exit(ent: Entity) -> void:
#     super(ent)

