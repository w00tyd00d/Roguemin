class_name _CLASS_ extends _BASE_


func _init():
    name = "_CLASS_SNAKE_CASE_"


## Called when entering the state
func enter(ent: Entity) -> void:
    super(ent)


## Attempts to perform an action to consume energy
func do_action(ent: Entity) -> Array:
    # Returns array of values:
    #   [0]: bool, Result of the action
    #   [1]: States.Enum, OPTIONAL new state
    return [false]


## Called when leaving the state
func exit(ent: Entity) -> void:
    super(ent)
