class_name UnitDead extends State


func _init():
    name = "unit_dead"


## Called when entering the state
func enter(ent: Entity) -> void:
    ent.target = null
    super(ent)


## Attempts to perform an action to consume energy
func do_action(_ent: Entity) -> Array:
    return [false]
