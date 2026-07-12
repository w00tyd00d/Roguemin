class_name DeadState extends InanimateState


func _init():
    name = "Dead"


func enter(_ent: Entity) -> void:
    var ent := _enemy(_ent)
    ent.self_modulate = Color(127/255.0, 127/255.0, 127/255.0)
    ent.buck_units()


## Attempts to perform an action to consume energy
func do_action(ent: Entity) -> ActionResult:
    var mte := _mte(ent)
    mte.get_hauled()
    return result(true)