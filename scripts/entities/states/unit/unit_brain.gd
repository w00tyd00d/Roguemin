class_name UnitBrain extends Brain

var is_idle : bool :
    get: return state == _states[States.Unit.IDLE]


func _init(unit: Unit) -> void:
    super(unit)
    _states = States.unit_states
    change_state(States.Unit.DEAD)


func update() -> bool:
    if entity.in_limbo:
        time = maxi(time, world.time)
        return false

    if entity.centroid == null:
        entity._calculate_centroid()

    return super()
