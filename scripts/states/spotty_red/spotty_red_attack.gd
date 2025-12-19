class_name SpottyRedAttack extends State


func _init():
    name = "spotty_red_attack"


func enter(_ent: Entity) -> void:
    var ent := _enemy(_ent)
    
    # We should only ever enter this state when we already have a target tile.
    assert(ent.target_tile)

    super(_ent)


# Changes what the cost of the action will be
func get_cost(_ent: Entity) -> int:
    return SpottyRed.ATTACK_SPEED


func do_action(_ent: Entity) -> ActionResult:
    var ent := _enemy(_ent)

    ent.attack_target()

    var new_target := ent.get_closest_target()
    
    if new_target:
        var dist := World.distance(ent.grid_position, new_target.grid_position, true)
        
        if dist <= ent.sight_range:
            ent.target_entity = new_target
            return result(true).new_state(States.SpottyRed.CHASE)
    
    return result(true).new_state(States.SpottyRed.RETURN)
