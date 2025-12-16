class_name SpottyRedChase extends State


func _init():
    name = "spotty_red_chase"


# Called when entering the state
func enter(_ent: Entity) -> void:
    super(_ent)
    _enemy(_ent).fov.update()



# Changes what the cost of the action will be
func get_cost(ent: Entity) -> int:
    return super(ent)


# Changes the rules for when the entity can act
func can_act(ent: Entity) -> bool:
    return super(ent)


# Changes how energy is consumed from the entity
func use_energy(ent: Entity, override := -1) -> void:
    super(ent, override)


# Attempts to perform an action to consume energy
func do_action(ent: Entity) -> ActionResult:
    
        
    return result(false)


# Called when leaving the state
func exit(ent: Entity) -> void:
    super(ent)

