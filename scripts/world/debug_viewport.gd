extends SubViewportContainer

func _gui_input(event: InputEvent) -> void:
    var world := GameState.world
    var grid_pos := Vector2i(world.get_global_mouse_position() / Vector2(Globals.TILE_SIZE))
    var chunk_pos := grid_pos / Globals.CHUNK_SIZE
    var tile := world.get_tile(grid_pos)
    var chunk := world.get_chunk(chunk_pos)
    var room := chunk.room if chunk else null

    var debug_string := "COH: {0}\nALI: {1}\nDST: {2}".format([
        Globals.BOID_COHESION_WEIGHT,
        Globals.BOID_ALIGNMENT_WEIGHT,
        Globals.BOID_DESTINATION_WEIGHT,

    ])

    debug_string += "\n({0},{1})\n({2},{3})\n({4},{5})".format([
        chunk_pos.x, chunk_pos.y,
        grid_pos.x % Globals.CHUNK_SIZE.x, grid_pos.y % Globals.CHUNK_SIZE.y,
        grid_pos.x, grid_pos.y
    ])

    # if room: debug_str += "\nRoom {0}".format([room.id])
    # if tile:
    #     debug_str += "\n{0}".format([tile.flow_field_value])
    #     debug_str += "\n{0}".format([tile.distance_from_wall])

    GameState.update_debug_info.emit(debug_string)

    var spawn_commands : Array[StringName] = [
        &"d_7",
        &"d_8",
        &"d_9",
        &"d_left_click"
    ]

    for cmd in spawn_commands:
        if not event.is_action_pressed(cmd):
            continue

        var type := Type.Unit.NONE

        match cmd:
            &"d_7": type = Type.Unit.RED
            &"d_8": type = Type.Unit.YELLOW
            &"d_9": type = Type.Unit.BLUE

        for i in 10:
            if world.unit_count == 100:
                break
            var unit := world.spawn_unit(grid_pos, type)
            # unit.state = Unit.State.IDLE
            unit.brain.change_state(States.Unit.IDLE)

    if event.is_action_pressed(&"d_right_click"):
        for unit in tile.get_all_units():
            unit.die()

    var boid_commands : Array[StringName] = [
        &"d_F9",
        &"d_F10",
        &"d_F11",
        &"d_F12"
    ]

    for cmd in boid_commands:
        if not event.is_action_pressed(cmd):
            continue

        var _val := 1.0 if Input.is_action_pressed(&"k_control") else 0.1
        var _sign := -1 if Input.is_action_pressed(&"k_shift") else 1

        match cmd:
            &"d_F10": Globals.BOID_COHESION_WEIGHT += _val * _sign
            &"d_F11": Globals.BOID_ALIGNMENT_WEIGHT += _val * _sign
            &"d_F12": Globals.BOID_DESTINATION_WEIGHT += _val * _sign
