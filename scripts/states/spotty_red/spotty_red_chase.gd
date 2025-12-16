class_name SpottyRedChase extends State

const NORMAL_COST := DEFAULT_COST * 2
const ROTATE_COST := DEFAULT_COST


func _init():
    name = "spotty_red_chase"


func enter(_ent: Entity) -> void:
    var ent := _enemy(_ent)
    
    # We should only be entering this state if we already have a target.
    assert(ent.target_entity)
    
    super(_ent)
    ent.fov.update()


# Changes what the cost of the action will be
func get_cost(_ent: Entity) -> int:
    return NORMAL_COST


# Changes the rules for when the entity can act
# func can_act(ent: Entity) -> bool:
#     return super(ent)


# Changes how energy is consumed from the entity
# func use_energy(ent: Entity, override := -1) -> void:
#     super(ent, override)


# Attempts to perform an action to consume energy
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
    if not ent.fov.all_targets.has(tar.grid_position):
        ent.turn_towards(ent.target_entity.grid_position)
        return result(true, ROTATE_COST)

    var tar_dist := World.distance(ent.grid_position, tar.grid_position, true)

    # If target within attack range, we attack.
    if tar_dist <= ent.attack_range:
        ent.prepare_attack(tar.current_tile)
        result(true).new_state(States.SpottyRed.ATTACK)
    
    return result(ent.move_towards(tar.current_tile))


# Called when leaving the state
# func exit(ent: Entity) -> void:
#     super(ent)


# Used only to change target to a more convenient target, not acquire a new one.
func _verify_target(ent: Enemy) -> Entity:
    assert(ent.target_entity)
    
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
        