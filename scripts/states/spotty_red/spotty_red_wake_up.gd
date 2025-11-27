class_name SpottyRedWakeUp extends State


func _init():
    name = "spotty_red_wake_up"


func enter(ent: Entity) -> void:
    ent.brain.reset_energy()
    super(ent)


func get_cost(_ent: Entity) -> int:
    return _def_cost * 2


func do_action(ent: Entity) -> Array:
    var enemy := _enemy(ent)
    var pos := enemy.grid_position
    var unit := GameState.unit_manager.get_closest_unit_to(pos)

    enemy.target_entity = unit
    
    return [true, States.SpottyRed.CHASE]

