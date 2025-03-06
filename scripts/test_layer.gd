extends DualMapLayer


func _ready() -> void:
    GameState.ASTAR_TEST.connect(_draw_points)
    
    
func _draw_points(arr: Array[Vector2i]) -> void:
    for pos in get_used_cells():
        set_background(pos, Glyph.NONE)
        set_glyph(pos, Glyph.NONE)

    for pos in arr:
        set_background(pos, Glyph.BLACK)
        set_glyph(pos, Glyph.TEST)
