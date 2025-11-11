class_name InanimateState extends State

func _init():
    name = "inanimate"


## Attempts to perform an action to consume energy
func do_action(ent: Entity) -> Array:
    var mte := ent as MultiTileEntity
    mte.get_hauled()
    return [true]
