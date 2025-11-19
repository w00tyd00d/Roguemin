class_name EnemyFOV extends RefCounted

# When computing visibility for a quadrant, indicate which axis is major.
enum _MajorAxis { X_AXIS, Y_AXIS }

const _OCTANTS : Dictionary[StringName, Array] = {
    &"NNW": [_MajorAxis.Y_AXIS, -1, -1],
    &"NNE": [_MajorAxis.Y_AXIS, -1, 1],
    &"SSW": [_MajorAxis.Y_AXIS, 1, -1],
    &"SSE": [_MajorAxis.Y_AXIS, 1, 1],
    &"WNW": [_MajorAxis.X_AXIS, -1, -1],
    &"WSW": [_MajorAxis.X_AXIS, -1, 1],
    &"ENE": [_MajorAxis.X_AXIS, 1, -1],
    &"ESE": [_MajorAxis.X_AXIS, 1, 1],
}

var _fovs : Dictionary[Direction, Array] = {
    Direction.north: [_OCTANTS[&"NNW"], _OCTANTS[&"NNE"]],
    Direction.south: [_OCTANTS[&"SSW"], _OCTANTS[&"SSE"]],
    Direction.west: [_OCTANTS[&"WNW"], _OCTANTS[&"WSW"]],
    Direction.east: [_OCTANTS[&"ENE"], _OCTANTS[&"ESE"]],
    Direction.northwest: [_OCTANTS[&"NNW"], _OCTANTS[&"WNW"]],
    Direction.northeast: [_OCTANTS[&"NNE"], _OCTANTS[&"ENE"]],
    Direction.southwest: [_OCTANTS[&"SSW"], _OCTANTS[&"WSW"]],
    Direction.southeast: [_OCTANTS[&"SSE"], _OCTANTS[&"ESE"]],
}

var _view_positions : Dictionary[Direction, Array] = {
    Direction.north: [],
    Direction.south: [],
    Direction.west: [],
    Direction.east: [],
    Direction.northwest: [],
    Direction.northeast: [],
    Direction.southwest: [],
    Direction.southeast: [],
}


# The world this map is attached to
var world : World :
    get: return GameState.world

# The enemy entity this sightline object is attached to
var entity: Enemy

# The maximum distance an enemy can see.
var max_distance: int

# The direction the enemy is facing in
var facing := Direction.north

# The cached target location for the enemy to focus on
var closest_target: Vector2i

# The cached location of of all targets within FOV
var all_targets: Array[Vector2i] = []


# Initialize the algorithm for a map of a particular size.
func _init(_ent: Enemy, _range: int) -> void:
    entity = _ent
    max_distance = _range


func reset() -> void:
    closest_target = Vector2()
    all_targets = []


# Compute the viewable cells from a particular view position by doing
# each of the eight octants of the view.
func update(positions: Array[Vector2i]) -> void:
    reset()

    var oct1 : Array[int] = _fovs[facing][0]
    var oct2 : Array[int] = _fovs[facing][1]
    var hist := {}

    for pos in positions:
        _compute_octant(oct1, pos, hist)
        _compute_octant(oct2, pos, hist)



func turn_towards(pos: Vector2i) -> void:
    var dest_dir := Direction.by_delta(entity.grid_position, pos)
    facing = Direction.by_turning(facing, dest_dir)


# Compute all visibile cells for one octant of the viewpoint.
func _compute_octant(
        octant: Array[int],
        view_position: Vector2,
        history: Dictionary) -> void:

    var axis := octant[0]
    var major_sign := octant[1]
    var minor_sign := octant[2]

    # Track occluders previously encountered in this octant.
    var occluders := []
    var new_occluders := []

    # Iterate along the major axis.
    for major in range(max_distance + 1):
        var any_transparent := false

        var position := view_position + _octant_to_offset(
            axis, major_sign * major, 0)
        if not world.in_bounds(position):
            break

        var position_delta := _octant_to_offset(axis, 0, minor_sign)

        # Clamp the iteration range to the map bounds, which allows us to skip
        # bounds check in the inner loop.
        var clamped_minor := _clamp_to_map_bounds(position, position_delta, major + 1)

        var angle_half_step := 0.5 / (major + 1) as float

        # Iterate along the minor axis, but not beyond the major axis distance.
        for minor in range(clamped_minor):
            # It is important to recompute angle each iteration, because the
            # alternative approach of accumulating angle_half_step introduces
            # noticible artifacts due to accumulation of floating point
            # precision error.
            var angle := minor as float / (major + 1) as float

            var cell_type := _get_cell_type(position)

            # Check if occluders found on previous lines block this cell.
            if not _is_occluded(occluders, angle, angle_half_step, cell_type != Type.Tile.WALL):
                
                if not history.has(position):
                    history[position] = true

                
                
                if cell_type != Type.Tile.WALL:
                    any_transparent = true
                else:
                    # The occluder represents a range of angle values, rather
                    # than a coordinate.
                    var occluder = Vector2(angle, angle + 2.0 * angle_half_step)
                    new_occluders.push_back(occluder)

            position += position_delta

        # If no tranparent cells were seen on this line, we can stop.
        if not any_transparent:
            break

        # Add any occluders we encountered on this line for checking
        # future lines.
        occluders = occluders + new_occluders
        new_occluders.clear()
    

# Clamp the range of iteration to the bounds of the map.  This returns a
# new maximum number of iterations, such that the iteration is entirely
# within the boundary of the map.
func _clamp_to_map_bounds(
    position: Vector2,
    position_delta: Vector2,
    iterations: int) -> int:

    var _size := world.size * Globals.CHUNK_SIZE

    if position.x + position_delta.x * iterations < 0:
        iterations = int(-position.x / position_delta.x) + 1
    if position.x + position_delta.x * iterations > _size.x:
        iterations = int((_size.x - position.x) / position_delta.x)

    if position.y + position_delta.y * iterations < 0:
        iterations = int(-position.y / position_delta.y) + 1
    if position.y + position_delta.y * iterations > _size.y:
        iterations = int((_size.y - position.y) / position_delta.y)

    return iterations


# Returns true if a cell within the quadrant should not be considered within
# the view.
#
# For cells which are themselves transparent, require visibility to the mid
# point as well as either of the sides of the cell.
#
# For cells which are not transparent, require only visiblity to one of the
# three tested points.
func _is_occluded(
        occluders: Array,
        angle: float,
        angle_half_step: float,
        transparent: bool) -> bool:

    var begin = _is_angle_occluded(occluders, angle)
    var mid = _is_angle_occluded(occluders, angle + angle_half_step)
    var end = _is_angle_occluded(occluders, angle + 2.0 * angle_half_step)

    if not transparent and (not begin or not mid or not end):
        return false

    if transparent and not mid and (not begin or not end):
        return false

    return true


# Given a list of occluded angle ranges and an angle test test, return
# true if the angle tested is occluded by at least one of the occluders.
func _is_angle_occluded(occluders: Array, angle: float) -> bool:
    for occluder in occluders:
        if angle >= occluder.x and angle <= occluder.y:
            return true

    return false


# Given a major axis, and offsets along the major and minor axes, return
# an equivalent (x, y) coordinate.
func _octant_to_offset(axis: int, major: int, minor: int) -> Vector2:
    if axis == _MajorAxis.Y_AXIS:
        return Vector2(minor, major)
    else:
        return Vector2(major, minor)


# is_transparent, but without a bounds check for use in the inner loop of
# visibility computation.
func _get_cell_type(position: Vector2) -> Type.Tile:
    return world.get_tile(position).type
    # return _transparent_cells[position.y][position.x]


# set_in_view, but with no bounds check.  For use in the inner loop of
# visibility computation.
# func _set_in_view_no_bounds(position: Vector2, in_view: bool) -> void:
#     _fov_cells[position.y][position.x] = in_view