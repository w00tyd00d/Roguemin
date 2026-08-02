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
    var best := INF
    var res: Unit = null

    # We're checking squared distance if radial, so we have to square
    # outside to match
    if radial and not is_zero_approx(outside):
        outside = outside * outside
    
    # We do a naive linear check for now, may implement a quadtree or k-d tree
    # in the future if queries become too taxing
    for unit: Unit in get_children():
        if unit.is_dead:
            continue
        
        var upos := unit.grid_position
        var dist := World.distance(pos, upos, radial, true)
        
        if dist < best and dist >= outside:
            res = unit
            best = dist
    
    return res
