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

var DEFAULT_GLYPH_KEY : Dictionary[Glyph, Array] = {
    Glyph.NORTH: [Direction.north],
    Glyph.SOUTH: [Direction.south],
    Glyph.WEST: [Direction.west],
    Glyph.EAST: [Direction.east],
    
    # Clockwise order
    Glyph.ZERO: [Direction.northwest],
    Glyph.ONE: [Direction.northeast],
    Glyph.TWO: [Direction.southeast],
    Glyph.THREE: [Direction.southwest],
}

var COMPACT_GLYPH_KEY : Dictionary[Glyph, Array] = {
    # Clockwise order
    Glyph.ZERO: [Direction.northwest, Direction.north],
    Glyph.ONE: [Direction.north, Direction.northeast],
    Glyph.TWO: [Direction.northeast, Direction.east],
    Glyph.THREE: [Direction.east, Direction.southeast],
    Glyph.FOUR: [Direction.southeast, Direction.south],
    Glyph.FIVE: [Direction.south, Direction.southwest],
    Glyph.SIX: [Direction.southwest, Direction.west],
    Glyph.SEVEN: [Direction.west, Direction.northwest],
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

# The cached target location for the enemy to focus on
var closest_target: Vector2i

# The cached location of of all targets within FOV
var all_targets: Dictionary[Vector2i, bool] = {}

var key : Dictionary[Glyph, Array] :
    get: 
        match entity.fov_type:
            Type.EnemyFov.COMPACT: return COMPACT_GLYPH_KEY
            _: return DEFAULT_GLYPH_KEY


# The target-checking callback, if there is one
var _target_cb : Callable :
    get:
        if _target_cb:
            return _target_cb
        return _default_target_callback



# Initialize the algorithm for a map of a particular size.
func _init(_ent: Enemy) -> void:
    entity = _ent


func reset() -> void:
    closest_target = Vector2()
    all_targets = {}


func set_target_callback(cb: Callable) -> void:
    _target_cb = cb


func add_view_position(dir: Direction, pos: Vector2i) -> void:
    _view_positions[dir].append(pos)


func get_view_positions(dir: Direction) -> Array:
    return _view_positions[dir]


func is_target_position(pos: Vector2i) -> bool:
    return all_targets.has(pos)


func can_see_entity(ent: Entity) -> bool:
    return is_target_position(ent.grid_position)


# Compute the viewable cells from a particular view position by doing
# each of the eight octants of the view.
func update() -> void:
    reset()

    var oct1 : Array = _fovs[entity.facing][0]
    var oct2 : Array = _fovs[entity.facing][1]
    var hist := {}

    for pos: Vector2i in _view_positions[entity.facing]:
        _compute_octant(oct1, entity.grid_position + pos, hist)
        _compute_octant(oct2, entity.grid_position + pos, hist)


# Compute all visibile cells for one octant of the viewpoint.
func _compute_octant(
        octant: Array,
        view_position: Vector2i,
        history: Dictionary) -> void:

    var axis: int = octant[0]
    var major_sign: int = octant[1]
    var minor_sign: int = octant[2]

    # Track occluders previously encountered in this octant.
    var occluders := []
    var new_occluders := []

    # Iterate along the major axis.
    for major in range(entity.sight_range + 1):
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
                    
                    if _is_target(position):
                        all_targets[position] = true
                        
                        var center := entity.center_from_facing()
                        var closer := Util.closer_than(position, closest_target, center)
                        
                        if closest_target == Vector2i() or closer:
                            closest_target = position
                
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
func _octant_to_offset(axis: int, major: int, minor: int) -> Vector2i:
    if axis == _MajorAxis.Y_AXIS:
        return Vector2i(minor, major)
    return Vector2i(major, minor)


func _get_cell_type(position: Vector2) -> Type.Tile:
    return world.get_tile(position).type


func _is_target(pos: Vector2i) -> bool:
    return _target_cb.call(pos)


func _default_target_callback(pos: Vector2i) -> bool:
    var tile := world.get_tile(pos)
    return tile.has_units or tile.has_player
