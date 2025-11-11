class_name UnitBrain extends Brain

var unit : Unit :
    get: return entity as Unit


func _init(_unit: Unit) -> void:
    super(_unit)
    _states = States.unit_states
    change_state(States.Unit.DEAD)


func update() -> bool:
    if unit.in_limbo:
        time = maxi(time, world.time)
        return false

    if unit.centroid == null and not unit.is_dead:
        unit._calculate_centroid()

    return super()
