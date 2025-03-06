class_name MultiTileEntity extends Entity

## Entities that stretch over many tiles, but make up a single object.

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


func _init() -> void:
    _scan()


func move_to(dest: Tile) -> void:
    var world := GameState.world
    for pos in area_positions:
        var tile := world.get_tile(grid_position + pos)
        if tile: tile.remove_entity(self)
    for pos in area_positions:
        var tile := world.get_tile(dest.grid_position + pos)
        tile.add_entity(self)
    
    last_position = grid_position
    grid_position = dest.grid_position


func within_radius(pos: Vector2i) -> bool:
    var dir := Direction.by_delta(grid_position, pos)
    var offset := Vector2i()
    if is_even:
        offset.x = -1 if dir.x < 0 else 0
        offset.y = -1 if dir.y < 0 else 0

    return pos.distance_to(grid_position + offset) < radius


func _scan() -> void:
    var size := get_used_rect().size
    radius = ceili(size.x / 2.0)
        
    var cx := 0.0 if size.x % 2 == 0 else 0.5
    var cy := 0.0 if size.y % 2 == 0 else 0.5
    center = Vector2(cx, cy)

    for pos in get_used_cells_by_id(0, Vector2(4,0)):
        latch_positions[pos] = true
        set_glyph(pos, Glyph.NONE)

    for pos in get_used_cells():
        area_positions.append(pos)