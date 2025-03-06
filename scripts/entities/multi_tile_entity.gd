class_name MultiTileEntity extends Entity

## Entities that stretch over many tiles, but make up a single object.

## The center tile of the entity in local coordinates
var center : Vector2i

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
        tile.remove_entity(self)
    for pos in area_positions:
        var tile := world.get_tile(dest + pos)
        tile.add_entity(self)
    
    last_position = grid_position
    grid_position = dest.grid_position


func _set_grid_position(pos: Vector2i) -> void:
    super(pos + center)


func _scan() -> void:
    var rect := get_used_rect()
    center = rect.size / 2

    for pos in get_used_cells_by_id(0, Vector2(4,0)):
        latch_positions[pos - center] = true
        set_glyph(pos, Glyph.NONE)

    for pos in get_used_cells():
        area_positions.append(pos - center)