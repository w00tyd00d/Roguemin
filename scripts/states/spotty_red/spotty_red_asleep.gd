class_name SpottyRedAsleep extends State


func _init():
    name = "spotty_red_asleep"


## Called when entering the state
func enter(ent: Entity) -> void:
    super(ent)


## Attempts to perform an action to consume energy
func do_action(ent: Entity) -> Array:
    
    return [false]


## Called when leaving the state
func exit(ent: Entity) -> void:
    super(ent)

