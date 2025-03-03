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
