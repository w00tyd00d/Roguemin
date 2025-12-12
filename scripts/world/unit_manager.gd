class_name UnitManager extends Node


func _ready() -> void:
    var i := 0
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


func get_closest_unit_to(pos: Vector2i, radial := false, outside := 0.0) -> Unit:
    var best := 2**31 - 1.0
    var res: Unit = null
    
    # We do a naive linear check for now, may implement a quadtree or k-d tree
    # in the future if queries become too taxing
    for unit: Unit in get_children():
        if unit.is_dead:
            continue
        
        var dist: float
        
        if radial:
            dist = unit.grid_position.distance_squared_to(pos)
        else:
            dist = Util.chebyshev_distance(unit.grid_position, pos)
        
        if dist < best and dist >= outside:
            res = unit
            best = dist
    
    return res
