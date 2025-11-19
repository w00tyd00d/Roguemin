class_name InanimateBrain extends MultiTileBrain

func _init(ent: Entity) -> void:
    _states = States.inanimate_states
    change_state(States.Inanimate.DEFAULT)
    super(ent)
