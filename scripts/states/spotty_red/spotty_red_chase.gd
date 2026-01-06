class_name SpottyRedChase extends State


func _init():
    name = "spotty_red_chase"


func enter(_ent: Entity) -> void:
    var ent := _enemy(_ent)
    
    # We should only be entering this state if we already have a target.
    assert(ent.target_entity)
    
    super(_ent)


# Changes what the cost of the action will be
func get_cost(_ent: Entity) -> int:
    return SpottyRed.MOVE_SPEED


func do_action(_ent: Entity) -> ActionResult:
    var ent := _enemy(_ent)
    var home_dist := World.distance(ent.grid_position, ent.spawn_position)
    
    # If we wandered too far from home, go home.
    if home_dist >= ent.wander_distance:
        return result(false).new_state(States.SpottyRed.RETURN)
    
    # Verify we have the best available target, if any.
    ent.target_entity = _verify_target(ent)

    # If we have no more target, go home.
    if not ent.target_entity:
        return result(false).new_state(States.SpottyRed.RETURN)

    var tar := ent.target_entity
    
    # If target not in fov, rotate towards them.
    if not ent.fov.can_see_entity(tar):
        ent.turn_towards(ent.target_entity.grid_position)
        return result(true, SpottyRed.ROTATE_SPEED)

    # If target within attack range, we attack.
    if ent.can_attack(tar.grid_position, true):
        var spotty_red := ent as SpottyRed
        var attack := spotty_red.bite_attack(tar.current_tile)
        
        ent.prepare_attack(attack)

        return result(true).new_state(States.SpottyRed.ATTACK)
    
    return result(ent.move_towards(tar.current_tile))


# Used only to change target to a more convenient target, not acquire a new one.
func _verify_target(ent: Enemy) -> Entity:
    assert(ent.target_entity)
    
    ent.fov.update()
    
    var fov_pos := ent.fov.closest_target
    var tar_pos := ent.target_entity.grid_position
    var eye_pos := ent.eye_position
    
    if not fov_pos and ent.distance_to(tar_pos) > ent.sight_range:
        return ent.get_closest_target(true)

    if (fov_pos == tar_pos or
        not Util.closer_than(fov_pos, tar_pos, eye_pos)):
        return ent.target_entity
        
    var tile := world.get_tile(fov_pos)

    return player if tile.has_player else tile.get_first_unit()
        
