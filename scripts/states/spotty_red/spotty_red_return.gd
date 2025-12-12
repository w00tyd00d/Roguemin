class_name SpottyRedReturn extends State


func _init():
    name = "spotty_red_return"


# Called when entering the state
func enter(ent: Entity) -> void:
    super(ent)


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
    # Returns array of values:
    #   [0]: bool, Result of the action
    #   [1]: States.Enum, OPTIONAL new state
    return result(false)


# Called when leaving the state
func exit(ent: Entity) -> void:
    super(ent)

