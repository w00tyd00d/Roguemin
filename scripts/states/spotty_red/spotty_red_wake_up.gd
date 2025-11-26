class_name SpottyRedWakeUp extends State


func _init():
    name = "spotty_red_wake_up"


# Called when entering the state
func enter(ent: Entity) -> void:
    ent.brain.reset_energy()
    super(ent)


# Changes what the cost of the action will be
func get_cost(ent: Entity) -> int:
    return Globals.TIME_SECOND * 2


# Changes the rules for when the entity can act
func can_act(ent: Entity) -> bool:
    return super(ent)


# Changes how energy is consumed from the entity
func use_energy(ent: Entity) -> void:
    super(ent)


# Attempts to perform an action to consume energy
func do_action(ent: Entity) -> Array:
    # Returns array of values:
    #   [0]: bool, Result of the action
    #   [1]: States.Enum, OPTIONAL new state
    return [false]


# Called when leaving the state
func exit(ent: Entity) -> void:
    super(ent)

