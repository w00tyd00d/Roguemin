class_name InanimateState extends State


func _init():
    name = "inanimate"


## Called when entering the state
func enter(ent: Entity) -> void:
    super(ent)


## Attempts to perform an action to consume energy
func do_action(ent: Entity) -> Array:
    var mte := ent as MultiTileEntity
    mte.get_hauled()
    return [true]


## Called when leaving the state
func exit(ent: Entity) -> void:
    super(ent)

