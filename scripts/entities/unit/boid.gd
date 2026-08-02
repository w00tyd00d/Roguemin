class_name Boid extends RefCounted


## The boolean toggle to indicate which centroid buffer variable we're
## currently watching.
static var centroid_buffer := false

## Shorthand for the current loaded world
var world : World :
    get: return GameState.world

## The unit this boid data is attached to
var unit: Unit

## Cached location of the unit's current boid centroid
var centroid : Centroid :
    get: return _centroid_b if Boid.centroid_buffer else _centroid_a
    set(cent):
        if Boid.centroid_buffer:
            _centroid_a = null
            _centroid_b = cent
        else:
            _centroid_a = cent
            _centroid_b = null
        # DEBUG
        # if cent != null:
        #     sightline_centroid.rotation = cent.cohesion_vector(unit.grid_position).angle()

var cohesion_vector : Vector2 :
    get:
        if centroid:
            return centroid.cohesion_vector(unit.grid_position)
        return Vector2()


## First centroid buffer slot
var _centroid_a : Centroid

## Second centroid buffer slot
var _centroid_b : Centroid

## Cached boid alignment vector
var _alignment_vector : Vector2i


func _init(_unit: Unit) -> void:
    unit = _unit


static func toggle_centroid_buffer() -> void:
    Boid.centroid_buffer = not Boid.centroid_buffer


func reset() -> void:
    _centroid_a = null
    _centroid_b = null
    _alignment_vector = Vector2()


func get_next_tile(dest: Tile) -> Tile:
    var dest_vec := Vector2(unit.grid_position).direction_to(Vector2(dest.grid_position))
    var cohe_vec := centroid.cohesion_vector(unit.grid_position)

    var bdw := Globals.BOID_DESTINATION_WEIGHT
    var dist := Util.chebyshev(unit.grid_position, unit.target.grid_position)
    var dest_weight := minf(bdw, bdw * dist / 4) # scale lower when within 4 tiles of target

    var boid_vector := (
        dest_vec * dest_weight +
        cohe_vec * Globals.BOID_COHESION_WEIGHT +
        _alignment_vector * Globals.BOID_ALIGNMENT_WEIGHT
    )

    # DEBUG
    # sightline_boid.rotation = boid_vector.angle()

    if boid_vector.length() < 0.2:
        return unit.current_tile

    var dir := Direction.by_normalized(boid_vector.normalized())

    return world.get_tile(unit.grid_position + dir.vector)


func calculate_centroid() -> void:
    var cent := Centroid.new()
    var data := _dfs_centroid_scan({})

    for _unit: Unit in data:
        cent.add_position(data[_unit])
        _unit.boid.centroid = cent


func _dfs_centroid_scan(history: Dictionary[Unit, Vector2i]) -> Dictionary:
    var res := Util.foreach_around_pos(unit.grid_position, 5, func(pos: Vector2i, data: Dictionary):
        var tile := world.get_tile(pos)

        if tile.has_units:
            var same_units := tile.get_units(unit.type)

            if same_units.is_empty():
                return

            if data.is_empty():
                data.centroid_sum = Vector2i()
                data.velocity_sum = Vector2i()
                data.count = 0
                data.units = []

            for nbr in same_units:
                if unit.next_destination == nbr.next_destination:
                    data.centroid_sum += tile.grid_position
                    data.velocity_sum += nbr.last_velocity
                    data.count += 1
                    data.units.append(nbr)
    )

    if res.is_empty():
        return history

    history[unit] = res.centroid_sum / res.count

    # We directly assign its local alignment while we have the data handy
    _alignment_vector = (Vector2(res.velocity_sum) / res.count)

    for nbr: Unit in res.units:
        if not history.has(nbr):
            nbr.boid._dfs_centroid_scan(history)

    return history


class Centroid:
    var count := 0
    var position : Vector2 :
        get:
            if position == Vector2():
                var res := Vector2()
                for vec in _vectors:
                    res += Vector2(vec)
                position = res / _vectors.size()
            return position

    var _vectors : Array[Vector2i]

    func add_position(vec: Vector2i) -> void:
        _vectors.append(vec)
        count += 1
        position = Vector2i() # Reset so it can re-memoize

    func cohesion_vector(pos: Vector2i) -> Vector2:
        return Vector2(pos).direction_to(position)
