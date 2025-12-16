class_name _CLASS_ extends _BASE_


func _init():
    name = "_CLASS_SNAKE_CASE_"


# Called when entering the state
func enter(ent: Entity) -> void:
    super(ent)


# Changes what the default cost of the action will be
# Essentially represents the speed of the action
func get_cost(_ent: Entity) -> int:
    return DEFAULT_COST


# Changes the rules for when the entity can act
func can_act(ent: Entity) -> bool:
    return super(ent)


# Changes how energy is consumed from the entity
func use_energy(ent: Entity, override := -1) -> void:
    super(ent, override)


# Returns ActionResult object with result(succes[, override]):
#   success: bool, Result of the action
#   override: int, OPTIONAL overridden energy cost
# Chain a .new_state(state) call to include:
#   state: enum, new state to enter
func do_action(ent: Entity) -> ActionResult:
    return result(false)


# Called when leaving the state
func exit(ent: Entity) -> void:
    super(ent)
