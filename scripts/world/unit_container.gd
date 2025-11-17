class_name UnitContainer extends Node


func _ready() -> void:
    var i = 0
    for unit: Unit in get_children():
        unit.id = i
        i += 1


func reset_all() -> void:
    for unit: Unit in get_children():
        unit.reset()


func get_available_unit() -> Unit:
    if GameState.world.unit_count == 100:
        return

    for unit: Unit in get_children():
        if unit.grid_position == Vector2i():
            return unit

    return null


func get_closest_unit_to(pos: Vector2i) -> Unit:
    var best := 2**31-1
    var res: Unit = null
    for unit: Unit in get_children():
        if unit.is_dead: continue
        var dist := Util.chebyshev_distance(unit.grid_position, pos)
        if dist < best:
            res = unit
            best = dist
    return res
