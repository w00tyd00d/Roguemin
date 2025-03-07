class_name MultiTileEntity extends Entity

## Entities that stretch over many tiles, but make up a single object.

## The type of multi-tile entity this entity is.
var type : Type.Entity

## The exact center point of the entity.
var center : Vector2

## The length from the center tile of the entity.
var radius : int

## The flag representing if the entity's bounding radius is even.
var is_even : bool :
    get: return center == Vector2()

## The local positions of the entity relative to its center.
var area_positions := []

## The latch points around the entity the units can attach to.
## In local coordinates from the center of the entity.
var latch_positions := {}

## Original spawn position of the entity.
var spawn_position : Vector2i

## The tile of the entity's spawn position.
var spawn_tile : Tile :
    get: return GameState.world.get_tile(spawn_position)

## A dictionary of any units currently hauling the entity.
var carriers := {}

## A cached value of the total amount of latch points around the entity.
var latch_point_count : int

## A cached value of how many carriers the entity has.
var carrier_count := 0

## A percentage value of energy built up from being carried. A value of
## [code]1.0[/code] allows the entity to act (move).
var carry_energy := 0.0


func _init() -> void:
    _scan()


func _ready() -> void:
    add_to_group(&"entities")


func delete() -> void:
    var world := GameState.world
    var player := GameState.player
    for pos in area_positions:
        var tile := world.get_tile(grid_position + pos)
        if tile: tile.remove_entity(self)
    
    for unit: Unit in carriers.keys():
        unit.drop_object()
        var dist := Util.chebyshev_distance(unit.grid_position, player.grid_position)
        if dist <= Globals.UNIT_SIGHT_RANGE:
            unit.join_squad()
        else:
            unit.go_idle()
    
    # Don't have time to set up an entity recycler, so just delete
    queue_free()


func move_to(dest: Tile) -> void:
    var world := GameState.world
    # We have to run twice since we reference the same entity
    for pos in area_positions:
        var tile := world.get_tile(grid_position + pos)
        if tile: tile.remove_entity(self)
    for pos in area_positions:
        var tile := world.get_tile(dest.grid_position + pos)
        tile.add_entity(self)
    
    for carrier: Unit in carriers:
        var pos : Vector2i = carriers[carrier]
        var tile := world.get_tile(dest.grid_position + pos)
        carrier.move_to(tile)
    
    last_position = grid_position
    grid_position = dest.grid_position


func move_towards(target: Tile) -> bool:
    var world := GameState.world
    var delta := target.grid_position - grid_position
    var ax := absi(delta.x)
    var ay := absi(delta.y)

    var vec : Vector2i

    if ax >= ay * 2: vec = Vector2i(delta.sign().x, 0)
    elif ay >= ax * 2: vec = Vector2i(0, delta.sign().y)
    else: vec = delta.sign()

    var valid := func(tile: Tile):
        return tile.type == Type.Tile.GRASS and tile._distance_from_wall >= radius

    var dir := Direction.by_pattern(vec)
    var dest := world.get_tile(grid_position + dir.vector)

    if valid.call(dest):
        move_to(dest)
        return true

    for _dir in dir.adjacent:
        if grid_position + _dir.vector == last_position: continue
        if valid.call(dest):
            move_to(dest)
            return true

    return false


func update_time(world_time: int) -> bool:
    var old_time := time
    time = world_time

    var time_units := time - old_time
    if add_and_check_energy(time_units):
        return do_action()
    
    return false


func within_radius(pos: Vector2i) -> bool:
    var dir := Direction.by_delta(grid_position, pos)
    var offset := Vector2i()
    if is_even:
        offset.x = -1 if dir.x < 0 else 0
        offset.y = -1 if dir.y < 0 else 0

    return pos.distance_to(grid_position + offset) < radius


func add_carrier(unit: Unit) -> bool:
    var pos := unit.grid_position - grid_position
    if not latch_positions.has(pos) or carriers.has(unit):
        return false

    carriers[unit] = pos
    latch_positions[pos] = false
    carrier_count += 1
    return true


func remove_carrier(unit: Unit) -> void:
    if not carriers.has(unit): return 

    unit.held_object = null
    latch_positions[carriers[unit]] = true
    carriers.erase(unit)
    carrier_count -= 1


func is_latch_position(pos: Vector2i) -> bool:
    return latch_positions.has(pos - grid_position)


## Returns an open latch position in world tile coordinates
func get_open_latch_tile() -> Tile:
    var world := GameState.world
    var filter := func(key): return latch_positions[key]
    var open := latch_positions.keys().filter(filter)
    if not open: return null
    
    var rpos : Vector2i = open.pick_random()
    return world.get_tile(rpos + grid_position)


func get_all_latch_tiles() -> Array[Tile]:
    var world := GameState.world
    var res : Array[Tile] = []

    for pos in latch_positions.keys():
        res.append(world.get_tile(pos + grid_position))
    
    return res


func collect() -> void:
    delete()


func get_next_flow_field_position() -> Vector2i:
    var vec := current_tile.get_flow_field_vector(radius)
    return grid_position + vec


func _get_can_act() -> bool:
    return energy_points >= Globals.ENERGY_CAP or carry_energy >= 1.0


func _scan() -> void:
    var size := get_used_rect().size
    radius = ceili(size.x / 2.0)
        
    var cx := 0.0 if size.x % 2 == 0 else 0.5
    var cy := 0.0 if size.y % 2 == 0 else 0.5
    center = Vector2(cx, cy)

    var latch_points := get_used_cells_by_id(0, Vector2(4,0))
    latch_point_count = latch_points.size()

    for pos in latch_points:
        latch_positions[pos] = true
        set_glyph(pos, Glyph.NONE)

    for pos in get_used_cells():
        area_positions.append(pos)


func _check_for_collection() -> void:
    var world := GameState.world
    var dist := Util.chebyshev_distance(grid_position, world.salvage_return_position)
    if dist < 3: collect()
