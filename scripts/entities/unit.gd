class_name Unit extends Entity

## The entity the [Player] controls to do tasks for them.

enum State {
    IDLE,
    FOLLOW,
    ATTACK,
    CARRY,
    RETURN,
    DEAD
}

## The boolean toggle to indicate which centroid buffer variable we're
## currently watching.
static var centroid_buffer := false

## The current type of the unit.
var type : Type.Unit

## Returns if the unit has been upgraded or not.
var upgraded : bool

## The current state of the unit.
var state := State.DEAD :
    set(new_state):
        var old_state = state
        state = new_state
        _on_state_exit(old_state)
        _on_state_enter(new_state)

## The current target of the unit.
var target

## The cached location which the unit last saw the player from, mainly used
## as a means for hauling MTEs in the void where there is no flow field to
## navigate.
var last_player_tile : Tile

## The object the unit is currently holding on to.
var held_object : MultiTileEntity

## The enemy the unit is current on top of, if at all.
var riding_enemy : Enemy

## A cached path to the unit's target.
var path : Array :
    set(arr):
        path = arr
        if not path.is_empty():
            GameState.ASTAR_TEST.emit(arr)

## The location of the next point along the unit's path
var next_destination : Vector2i :
    get:
        if not path.is_empty():
            return path[0]
        elif target:
            return target.grid_position

        return Vector2i()

## Cached location of the unit's current boid centroid
var centroid : Centroid :
    get: return _centroid_b if Unit.centroid_buffer else _centroid_a
    set(cent):
        if Unit.centroid_buffer:
            _centroid_a = null
            _centroid_b = cent
        else:
            _centroid_a = cent
            _centroid_b = null
        # DEBUG
        if cent != null:
            sightline_centroid.rotation = cent.cohesion_vector(grid_position).angle()

var cohesion_vector : Vector2 :
    get:
        if centroid:
            return centroid.cohesion_vector(grid_position)
        return Vector2()

## A flag representing if the unit is idle.
var idle : bool :
    get: return state == State.IDLE

## A flag representing if the unit is in limbo (ie: not in the field).
var in_limbo : bool :
    get: return grid_position == Vector2i()

## A flag for whether not the unit is allowed to stack with other units
var can_stack : bool :
    get: return state == State.ATTACK

## First centroid buffer slot
var _centroid_a : Centroid

## Second centroid buffer slot
var _centroid_b : Centroid

## Cached boid alignment vector
var _alignment_vector : Vector2i


# DEBUG
@onready var sightline_boid := $Sightline1 as ColorRect
@onready var sightline_centroid := $Sightline2 as ColorRect
#


func _ready() -> void:
    add_to_group(&"units")


static func metadata(_type: Type.Unit) -> Dictionary:
    match _type:
        Type.Unit.RED: return { name = "Red", color = Color.RED }
        Type.Unit.YELLOW: return { name = "Yellow", color = Color.YELLOW }
        Type.Unit.BLUE: return { name = "Blue", color = Color.BLUE }
        Type.Unit.NONE: return { name = "None", color = Color.DARK_GRAY }
    return {}


static func toggle_centroid_buffer() -> void:
    Unit.centroid_buffer = not Unit.centroid_buffer


func get_metadata() -> Dictionary:
    return Unit.metadata(type)


func update() -> bool:
    if in_limbo:
        time = maxi(time, world.time)
        return false

    if centroid == null:
        _calculate_centroid()

    return super()


func do_action() -> bool:
    match state:
        State.FOLLOW:
            return _do_follow_action()
        State.CARRY:
            if not held_object:
                if target.is_latch_position(grid_position):
                    grab_object(target)
                    return false
                return move_towards(target.current_tile)
        State.ATTACK:

            pass
        State.RETURN:
            return move_towards(world.unit_ship_tile)

    return false


func reset() -> void:
    hide()

    modulate.a = 1
    set_background(Vector2(), Glyph.BLACK)

    time = 0
    action_energy = 0
    posture_points = 0

    if player:
        player.remove_unit(self)

    if current_tile:
        current_tile.remove_unit(self)

    if not state == State.DEAD and world:
        var count := world.unit_count
        world.unit_count = maxi(count-1, 0)

    if held_object:
        drop_object()

    target = null
    state = State.IDLE
    grid_position = Vector2()
    last_player_tile = null

    # _centroid_a = Vector2i()
    centroid = null


func spawn(pos: Vector2i, _type: Type.Unit, _upgraded := false) -> void:
    type = _type
    upgraded = true # No time to implement nectar :(
    grid_position = pos
    state = State.FOLLOW if _in_range_of_tether() else State.IDLE
    show()


func upgrade() -> void:
    if upgraded: return
    upgraded = true
    _update_glyph()


func die() -> void:
    state = State.DEAD

    player.remove_unit(self)
    current_tile.remove_unit(self)

    var count := world.unit_count
    world.unit_count = maxi(count-1, 0)

    set_glyph(Vector2(), Glyph.UNIT_GHOST_LARGE)
    set_background(Vector2(), Glyph.NONE)
    z_index += 1

    var end_pos := position + Vector2(Direction.north.vector * Globals.TILE_SIZE * 2)

    var tween := create_tween()
    tween.tween_property(self, "position", end_pos, 1.5)
    tween.parallel().tween_property(self, "modulate:a", 0, 1.25)
    tween.tween_callback(func():
        z_index -= 1
        reset()
    )


func move_to(dest: Tile) -> void:
    world.move_unit(self, dest)
    last_position = grid_position
    grid_position = dest.grid_position


func swap_with(dest: Tile) -> bool:
    var units := dest.get_all_units()

    if (units.size() > 1 or                 # Can't swap with multiple units
        last_position == grid_position):    # Prevent oscillation
            return false

    # Do a centroid distance check
    #var dist1 := Util.chebyshev_distance(centroid.position, grid_position)
    #var dist2 := Util.chebyshev_distance(centroid.position, dest.grid_position)

    var dist1 := centroid.position.distance_to(grid_position)
    var dist2 := centroid.position.distance_to(dest.grid_position)

    # NOT CHECKING DISTANCE OF OTHER UNIT'S CENTROID MIGHT CAUSE OSCILLATION
    # LEAVING IT SIMPLE FOR NOW
    if dist1 <= dist2:
        return false

    var nbr := units[0]

    # MAY NEED TO CHANGE FOR ATTACKING PURPOSES
    if nbr.type == type:
        return false

    if nbr.centroid and nbr.centroid.count > 1:
        #var ndist1 := Util.chebyshev_distance(nbr.centroid.position, nbr.grid_position)
        #var ndist2 := Util.chebyshev_distance(nbr.centroid.position, nbr.grid_position)

        # Check distance from current position to neighbors centroid to see
        # what their new distance would be if they moved
        var ndist := grid_position.distance_to(nbr.centroid.position)

        if ndist > dist2:
            return false

    nbr.move_to(current_tile)
    move_to(dest)

    return true


func move_towards(dest: Tile) -> bool:
    var boid_tile := _apply_boid_calculation(dest)

    if boid_tile == current_tile:
        return false

    #var delta := boid_tile.grid_position - grid_position
    #var ax := absi(delta.x)
    #var ay := absi(delta.y)

    #var vec : Vector2i
#
    #if ax >= ay * 2: vec = Vector2i(delta.sign().x, 0)
    #elif ay >= ax * 2: vec = Vector2i(0, delta.sign().y)
    #else: vec = delta.sign()

    #var dir := Direction.by_pattern(dir.vector)
    var dir := Direction.by_delta(grid_position, boid_tile.grid_position)

    if not dir or dir == Direction.none:
        return false

    var res := _check_tile_at(grid_position + dir.vector)
    var next_tile := world.get_tile(grid_position + dir.vector)

    match res:
        Type.Tile.WALL:
            if state == State.RETURN and Tag.has(next_tile, Tags.UNIT_SHIP):
                reset()
                return true # We reset, so no action cost needed
            elif current_tile.type == Type.Tile.VOID:
                return _do_move_action(next_tile)

        Type.Tile.ENTITY:
            # Has units, but not entities
            if not next_tile.has_entities:
                if _do_move_action(next_tile):
                    return true
        _:
            return _do_move_action(next_tile)

    var dist := grid_position.distance_to(target.grid_position)
    var limit := 8

    if dist < 1.5:
        return false

    for adj_dir in dir.adjacent:
        #if (grid_position + adj_dir.vector == last_position and dist <= limit or
            #dir.orthogonal.has(last_direction)):
            #continue
        var res2 := _check_tile_at(grid_position + adj_dir.vector)
        match res2:
            Type.Tile.WALL:
                continue
            Type.Tile.GRASS:
                next_tile = world.get_tile(grid_position + adj_dir.vector)
                return _do_move_action(next_tile)
            Type.Tile.ENTITY:
                # Has units, but not entities
                if not next_tile.has_entities:
                    if _do_move_action(next_tile):
                        return true
        continue

    var cheby := Util.chebyshev_distance(grid_position, target.grid_position)
    if cheby <= limit:
        return false

    for ort_dir in dir.orthogonal:
        if grid_position + ort_dir.vector == last_position:
            continue
        if _check_tile_at(grid_position + ort_dir.vector) == Type.Tile.GRASS:
            next_tile = world.get_tile(grid_position + ort_dir.vector)
            return _do_move_action(next_tile)

    return false


func throw_to(tile: Tile) -> void:
    last_player_tile = player.current_tile

    if tile.has_entities:
        var ent := tile.get_first_entity()
        if ent:
            match ent.type:
                Type.Entity.TREASURE:
                    var latch := ent.get_open_latch_tile()
                    if latch:
                        target_entity(ent)
                        move_to(latch)
                        grab_object(ent)
                        return

        tile = world.get_closest_empty_tile(tile)

    action_energy = 0

    move_to(tile)
    _go_idle()


func join_squad() -> void:
    last_player_tile = null
    state = State.FOLLOW
    player.add_unit(self)


func dismiss() -> void:
    last_player_tile = player.current_tile
    _go_idle()


func go_home() -> void:
    state = State.RETURN


func ride_enemy(enemy: Enemy) -> void:
    if riding_enemy: return
    enemy.add_unit(self)
    riding_enemy = enemy


func get_off_enemy() -> void:
    if not riding_enemy: return
    riding_enemy.remove_unit(self)

    move_to(world.get_closest_empty_tile(riding_enemy.current_tile))
    riding_enemy = null


func target_entity(ent: MultiTileEntity) -> void:
    target = ent
    match ent.type:
        Type.Entity.TREASURE: state = State.CARRY
        Type.Entity.ENEMY: state = State.ATTACK


func grab_object(obj: MultiTileEntity) -> bool:
    if obj.add_carrier(self):
        held_object = obj
        return true

    return false


func drop_object() -> void:
    if not held_object: return
    held_object.remove_carrier(self)
    held_object = null


func _go_idle() -> void:
    state = State.IDLE
    player.remove_unit(self)


func _do_follow_action() -> bool:
    if not player: return false

    if name == "Unit96":
        pass

    var tether := player.unit_tether
    var dest := tether.tail.current_tile

    if not _in_range_of_tether():
        _go_idle()
        return false

    if _can_see_tether():
        path = []
        return move_towards(dest)

    if (path.is_empty() or
        Util.chebyshev_distance(path[0], dest.grid_position) >= 5):
            # We get the path in reverse to use as a stack
            path = world.astar.get_id_path(dest.grid_position, grid_position)
            _broadcast_path()

    if path.is_empty():
        return false

    var dist := Util.chebyshev_distance(current_tile.grid_position, path[-1])
    if dist < 2:
        path.pop_back()
    if not path.is_empty():
        return move_towards(world.get_tile(path[-1]))

    return false


func _calculate_centroid() -> void:
    var cent := Centroid.new()
    var data := _dfs_centroid_scan({})

    for unit: Unit in data:
        cent.add_position(data[unit])
        unit.centroid = cent


func _dfs_centroid_scan(history: Dictionary[Unit, Vector2i]) -> Dictionary:
    var res := Util.foreach_around_pos(grid_position, 5, func(pos: Vector2i, data: Dictionary):
        var tile := world.get_tile(pos)

        if tile.has_units:
            var same_units := tile.get_units(type)

            if same_units.is_empty():
                return

            if data.is_empty():
                data.centroid_sum = Vector2i()
                data.velocity_sum = Vector2i()
                data.count = 0
                data.units = []

            for unit in same_units:
                if next_destination == unit.next_destination:
                    data.centroid_sum += tile.grid_position
                    data.velocity_sum += unit.last_velocity
                    data.count += 1
                    data.units.append(unit)
    )

    if res.is_empty():
        return history

    history[self] = res.centroid_sum / res.count

    # We directly assign its local alignment while we have the data handy
    _alignment_vector = (Vector2(res.velocity_sum) / res.count)

    for unit: Unit in res.units:
        if not history.has(unit):
            unit._dfs_centroid_scan(history)

    return history


func _apply_boid_calculation(dest: Tile) -> Tile:
    var dest_vec := Vector2(grid_position).direction_to(Vector2(dest.grid_position))
    var cohe_vec := centroid.cohesion_vector(grid_position)

    #var cohe_weight := Globals.BOID_COHESION_WEIGHT
    var bdw := Globals.BOID_DESTINATION_WEIGHT
    var dist := Util.chebyshev_distance(grid_position, target.grid_position)
    var dest_weight := minf(bdw, bdw * dist / 4) # scale lower when within 10 tiles of target

    var boid_vector := (
        dest_vec * dest_weight +
        cohe_vec * Globals.BOID_COHESION_WEIGHT +
        _alignment_vector * Globals.BOID_ALIGNMENT_WEIGHT
    )

    # DEBUG
    sightline_boid.rotation = boid_vector.angle()

    if boid_vector.length() < 0.2:
        return current_tile

    # DEBUG
    # var delta := dest.grid_position - grid_position
    # var original_vector : Vector2i

    # if absi(delta.x) >= absi(delta.y) * 2: original_vector = Vector2i(delta.sign().x, 0)
    # elif absi(delta.y) >= absi(delta.x) * 2: original_vector = Vector2i(0, delta.sign().y)
    # else: original_vector = delta.sign()

    # print("Original Vector : ", original_vector)
    # print("Normalized Vector : ", dest_vec)
    # print("Flocking Vector : ", boid_vector.normalized())

    var dir := Direction.by_normalized(boid_vector.normalized())

    # print("Resulting Vector : ", dir.vector, "\n")

    return world.get_tile(grid_position + dir.vector)



# func _apply_boid_calculation_old(dest: Tile) -> Tile:
#     var area := Util.get_square_around_pos(grid_position, 5, true)

#     var cohesion_sum := Vector2i()
#     var alignment_sum := Vector2i()
#     var avoidance_sum := Vector2i()

#     var count := 0

#     for pos in area:
#         if pos == grid_position: continue

#         var tile := world.get_tile(pos)
#         var dist := Util.chebyshev_distance(tile.grid_position, grid_position)

#         if tile.has_units:
#             var same_units := tile.get_units(type)

#             if not same_units.is_empty():
#                 cohesion_sum += tile.grid_position
#                 alignment_sum += same_units[0].last_velocity
#                 count += 1

#                 if dist == 1:
#                     avoidance_sum += grid_position - tile.grid_position

#         if (dist == 1 and (tile.has_entities or
#             current_tile.walkable and tile.type == Type.Tile.WALL)):
#             avoidance_sum += grid_position - tile.grid_position

#     #region
#     var cohesion := Vector2()
#     var alignment := Vector2()

#     if count > 0:
#         var _centroid := Vector2(cohesion_sum) / count
#         _centroid_a = _centroid

#         Vector2(_centroid - Vector2(grid_position)).normalized()
#         Vector2(Vector2(alignment_sum) / count - Vector2(last_velocity)).normalized()

#     var avoidance := Vector2(avoidance_sum).normalized()
#     var destination := Vector2(dest.grid_position - grid_position).normalized()
#     #endregion

#     var vector := (
#         cohesion * Globals.BOID_COHESION_WEIGHT +
#         alignment * Globals.BOID_ALIGNMENT_WEIGHT +
#         avoidance * Globals.BOID_AVOIDANCE_WEIGHT +
#         destination * Globals.BOID_DESTINATION_WEIGHT
#     ).normalized()

#     var result : Tile

#     if is_equal_approx(vector.x, vector.y):
#         if is_zero_approx(vector.x):
#             result = current_tile
#         else:
#             var dir := Direction.by_pattern(Vector2i(vector.sign()))
#             var adj := dir.adjacent.pick_random() as Direction
#             result = current_tile.get_neighbor(adj)

#     else:
#         var dir := Direction.by_pattern(Vector2i(vector.round()))
#         result = current_tile.get_neighbor(dir)

#     return result


func _do_move_action(dest: Tile) -> bool:
    # ALLOW TO BE MODIFIED BY BEING BOOSTED WITH SPICY SPRAY
    # AND RUSH BOOTS!
    var step := Globals.DEFAULT_ENERGY_STEP
    var dist := Util.chebyshev_distance(grid_position, player.grid_position)
    var cost := step - 20 if state == State.FOLLOW and dist > 8 else step

    if dest.has_units and not can_stack:
        if not swap_with(dest):
            return false
    else:
        move_to(dest)

    # move_to(dest)

    action_energy -= cost
    return true


func _spend_attack_action() -> bool:
    # ALLOW TO BE MODIFIED BY BEING BOOSTED WITH SPICY SPRAY
    # AND POSSIBLY RUSH BOOTS!
    var cost := Globals.DEFAULT_ENERGY_STEP

    action_energy -= cost
    return true


func _in_range_of_tether() -> bool:
    var limit := Globals.UNIT_SIGHT_RANGE
    var dest := player.unit_tether.tail.grid_position
    return Util.chebyshev_distance(grid_position, dest) <= limit


func _can_see_tether() -> bool:
    var tail := player.unit_tether.tail

    var callback := func(ctx: DDARC.Context):
        var pos := ctx.grid_position
        if (not world.in_bounds(pos) or
            world.query_tile_at(pos) == Type.Tile.WALL and not
            current_tile.type == Type.Tile.VOID):
                return true

    var raycast := DDARC.to_grid_position(
        grid_position,
        tail.grid_position,
        callback
    )

    return raycast.grid_position == tail.grid_position


func _check_tile_at(pos: Vector2i) -> Type.Tile:
    var tile := world.get_tile(pos)
    var res := world.query_tile(tile)

    # Cascade forward to see if we can resolve movement
    if res == Type.Tile.ENTITY:
        var any := false
        for unit in tile.get_all_units():
            if unit.time < world.time and unit.update():
                any = true
        if any:
            return _check_tile_at(pos)

    return res


func _broadcast_path() -> void:
    if path.is_empty(): return

    var hist := {}
    var tiles := current_tile.get_all_neighbors()

    for _i in 2:
        var new_tiles : Array[Tile] = []

        for tile in tiles:
            if hist.has(tile):
                continue
            hist[tile] = true

            for unit in tile.get_all_units():
                var empty_path := unit.path.is_empty()
                if unit.target == target and (empty_path or unit.path[0] != path[0]):
                    unit._receive_path(path)

            new_tiles.append(tile)


func _receive_path(_path: Array[Vector2i]) -> void:
    _path = _path.duplicate()
    while not _path.is_empty():
        var dist1 := Util.chebyshev_distance(_path[0], _path[-1])
        var dist2 := Util.chebyshev_distance(grid_position, _path[-1])
        if dist1 < dist2:
            path = _path
            return
        _path.pop_front()


func _update_glyph() -> void:
    match type:
        Type.Unit.RED:
            if upgraded:
                if idle: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE)
            elif idle: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL)
        Type.Unit.YELLOW:
            if upgraded:
                if idle: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE)
            elif idle: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL)
        Type.Unit.BLUE:
            if upgraded:
                if idle: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE_IDLE)
                else: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE)
            elif idle: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL_IDLE)
            else: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL)


func _on_state_enter(_state: State) -> void:
    match _state:
        State.IDLE:
            _update_glyph()
        State.FOLLOW:
            target = player.unit_tether.tail
            player.add_unit(self)
        State.ATTACK:
            player.remove_unit(self)
        State.CARRY:
            player.remove_unit(self)
        State.RETURN:
            target = world.unit_ship_tile


func _on_state_exit(_state: State) -> void:
    match _state:
        State.IDLE:
            _update_glyph()
        State.CARRY:
            drop_object()


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
        # Reset grid_position so it recalculates
        position = Vector2i()

    func cohesion_vector(pos: Vector2i) -> Vector2:
        return Vector2(pos).direction_to(position)
