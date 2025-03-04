extends SubViewportContainer

func _gui_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"d_left_click"):
        var world := GameState.world
        var grid_pos := Vector2i(world.get_global_mouse_position() / Vector2(Globals.TILE_SIZE))
        world.spawn_unit(grid_pos)
