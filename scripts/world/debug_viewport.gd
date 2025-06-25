extends SubViewportContainer

func _gui_input(event: InputEvent) -> void:
    var world := GameState.world
    var grid_pos := Vector2i(world.get_global_mouse_position() / Vector2(Globals.TILE_SIZE))
    var chunk_pos := grid_pos / Globals.CHUNK_SIZE
    var tile := world.get_tile(grid_pos)
    var chunk := world.get_chunk(chunk_pos)
    var room := chunk.room if chunk else null

    var debug_str := "({0},{1})".format([chunk_pos.x, chunk_pos.y])

    if room: debug_str += "\nRoom {0}".format([room.id])
    if tile:
        debug_str += "\n{0}".format([tile.flow_field_value])
        debug_str += "\n{0}".format([tile.distance_from_wall])

    GameState.update_debug_info.emit(debug_str)

    if event.is_action_pressed(&"d_left_click"):
        for i in 10:
            if world.unit_count == 100:
                break
            var unit := world.spawn_unit(grid_pos)
            unit.state = Unit.State.IDLE

    elif event.is_action_pressed(&"d_right_click"):
        for unit in tile.get_all_units():
            unit.die()
