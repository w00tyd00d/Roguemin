@tool

class_name RoomBlueprint extends TileMapLayer

## A [TileMapLayer] node that automatically fetches and aggregates
## tilemap data to be used later, such as instantiating setpieces.

const BORDER_THICKNESS := 1
const BORDER_HALF_VEC := Vector2(BORDER_THICKNESS / 2.0, BORDER_THICKNESS / 2.0)

## The size, in world nodes, the room consists of
@export var size : Vector2i :
    set(vec):
        size = vec
        queue_redraw()

## The chunk along the top of the room that contains an exit.
@export var top_exit := -1 :
    set(n):
        top_exit = clampi(n, -1, size.x-1)
        queue_redraw()
## The chunk along the bottom of the room that contains an exit.
@export var bottom_exit := -1 :
    set(n):
        bottom_exit = clampi(n, -1, size.x-1)
        queue_redraw()
## The chunk along the left of the room that contains an exit.
@export var left_exit := -1 :
    set(n):
        left_exit = clampi(n, -1, size.y-1)
        queue_redraw()
## The chunk along the right of the room that contains an exit.
@export var right_exit := -1 :
    set(n):
        right_exit = clampi(n, -1, size.y-1)
        queue_redraw()


## The dictionary of tile positions and their respective glyph information.
var tile_data : Dictionary[Vector2i, Glyph] = {}

## The dictionary of exit data pre-baked into the dictionary.
var exit_data : Dictionary[Vector2i, int] :
    get:
        var dirs : Dictionary[Vector2i, int] = {
            Vector2i(0,-1): top_exit,
            Vector2i(0, 1): bottom_exit,
            Vector2i(-1,0): left_exit,
            Vector2i(1, 0): right_exit,
        }
        return dirs

## The dictionary of context positions set up within the blueprint.
var context_positions : Dictionary[int, Array] = {}


func _init() -> void:
    _scan()


# DEBUG: Draws a square border in the editor
func _draw() -> void:
    if not Engine.is_editor_hint(): return

    print(exit_data)

    _draw_border()
    _draw_exits()


func _draw_border() -> void:
    const SIZE_OUTER := Vector2i(23, 23) * Globals.TILE_SIZE
    const SIZE_INNER := Vector2i(15, 15) * Globals.TILE_SIZE

    var rect1_w := size.x * SIZE_OUTER.x + BORDER_THICKNESS
    var rect1_h := size.y * SIZE_OUTER.y + BORDER_THICKNESS

    var rect2_w := size.x * SIZE_INNER.x + ((size.x - 1) * 64) + BORDER_THICKNESS
    var rect2_h := size.y * SIZE_INNER.y + ((size.y - 1) * 64) + BORDER_THICKNESS

    var rect1 := Rect2(-BORDER_HALF_VEC, Vector2(rect1_w, rect1_h))
    var rect2 := Rect2(Vector2(Globals.TILE_SIZE) * 4 - BORDER_HALF_VEC, Vector2(rect2_w, rect2_h))

    draw_rect(rect1, Color.RED, false, BORDER_THICKNESS)
    draw_rect(rect2, Color.GREEN, false, BORDER_THICKNESS)


func _draw_exits() -> void:
    const CHUNK_SIZE := Globals.CHUNK_SIZE.x

    var border := Vector2i(BORDER_THICKNESS, BORDER_THICKNESS)
    var size_h := Vector2i(15, 4) * Globals.TILE_SIZE + border - Vector2i.ONE
    var size_v := Vector2i(4, 15) * Globals.TILE_SIZE + border - Vector2i.ONE

    for dir in exit_data:
        var val := exit_data[dir]
        if val == -1: continue

        var delta := (val * Globals.TILE_SIZE.x) * CHUNK_SIZE + 4 * Globals.TILE_SIZE.x
        var limit := (size * CHUNK_SIZE - Vector2i(4,4)) * Globals.TILE_SIZE 

        var pos : Vector2
        var dim : Vector2i

        match dir:
            Vector2i(0,-1):
                pos = Vector2(delta, 0) - BORDER_HALF_VEC
                dim = size_h
            Vector2i(0,1):
                pos = Vector2(delta, limit.y) + BORDER_HALF_VEC
                dim = size_h
            Vector2i(-1,0):
                pos = Vector2(0, delta) - BORDER_HALF_VEC
                dim = size_v
            Vector2i(1,0):
                pos = Vector2(limit.x, delta) + BORDER_HALF_VEC
                dim = size_v

        draw_rect(Rect2(pos, dim), Color.YELLOW, false, BORDER_THICKNESS)


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
