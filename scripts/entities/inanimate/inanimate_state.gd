class_name InanimateState extends State


func _init():
    name = "inanimate"


## Attempts to perform an action to consume energy
func do_action(ent: Entity) -> ActionResult:
    var mte := _mte(ent)
    mte.get_hauled()
    return result(true)
