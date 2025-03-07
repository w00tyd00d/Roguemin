class_name UnitContainer extends Node


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
        if unit.in_limbo: continue
        var dist := Util.chebyshev_distance(unit.grid_position, pos)
        if dist < best:
            res = unit
            best = dist
    return res