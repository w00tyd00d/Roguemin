extends SubViewportContainer

func _gui_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"d_left_click"):
        var world := GameState.world
        var grid_pos := Vector2i(world.get_global_mouse_position() / Vector2(Globals.TILE_SIZE))
        for i in 10:
            world.spawn_unit(grid_pos)
    elif event.is_action_pressed(&"d_right_click"):
        var world := GameState.world
        var grid_pos := Vector2i(world.get_global_mouse_position() / Vector2(Globals.TILE_SIZE))
        var tile := world.get_tile(grid_pos)
        for unit in tile.get_all_units():
            unit.die()
