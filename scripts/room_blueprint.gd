@tool

class_name RoomBlueprint extends TileMapLayer

## A [TileMapLayer] node that automatically fetches and aggregates
## tilemap data to be used later, such as instantiating setpieces.

## The size, in world nodes, the room consists of
@export var size : Vector2i :
    set(vec):
        size = vec
        queue_redraw()

## The chunk along the top of the room that contains an exit.
@export var top_exit := -1 :
    set(n): top_exit = clampi(n, -1, size.x-1)
## The chunk along the bottom of the room that contains an exit.
@export var bottom_exit := -1 :
    set(n): bottom_exit = clampi(n, -1, size.x-1)
## The chunk along the left of the room that contains an exit.
@export var left_exit := -1 :
    set(n): left_exit = clampi(n, -1, size.x-1)
## The chunk along the right of the room that contains an exit.
@export var right_exit := -1 :
    set(n): right_exit = clampi(n, -1, size.x-1)


## The dictionary of tile positions and their respective glyph information.
var tile_data := {}

## The dictionary of context positions set up within the blueprint.
var context_positions := {}


func _init() -> void:
    _scan()


# DEBUG: Draws a square border in the editor
func _draw() -> void:
    if not Engine.is_editor_hint(): return

    const BORDER_THICKNESS := 1
    const BORDER_HALF_VEC := Vector2(BORDER_THICKNESS / 2.0, BORDER_THICKNESS / 2.0)

    const NODE_SIZE_OUTER := Vector2i(23, 23) * Globals.TILE_SIZE
    const NODE_SIZE_INNER := Vector2i(15, 15) * Globals.TILE_SIZE

    var rect1_w := size.x * NODE_SIZE_OUTER.x + BORDER_THICKNESS
    var rect1_h := size.y * NODE_SIZE_OUTER.y + BORDER_THICKNESS

    var rect2_w := size.x * NODE_SIZE_INNER.x + ((size.x - 1) * 64) + BORDER_THICKNESS
    var rect2_h := size.y * NODE_SIZE_INNER.y + ((size.y - 1) * 64) + BORDER_THICKNESS

    var rect1 := Rect2(-BORDER_HALF_VEC, Vector2(rect1_w, rect1_h))
    var rect2 := Rect2(Vector2(Globals.TILE_SIZE) * 4 - BORDER_HALF_VEC, Vector2(rect2_w, rect2_h))
    draw_rect(rect1, Color.RED, false, BORDER_THICKNESS)
    draw_rect(rect2, Color.GREEN, false, BORDER_THICKNESS)


func _run_context_procedures(_world: World, _start: Vector2i) -> void:
    pass


func _scan() -> void:
    for vec in get_used_cells():
        var glyph := Glyph.get_from(self, vec)
        var ctx_id := glyph.get_context_id()
        if ctx_id > -1:
            context_positions.get_or_add(ctx_id, []).append(vec)
            tile_data[vec] = Glyph.GRASS
        else:
            tile_data[vec] = glyph
