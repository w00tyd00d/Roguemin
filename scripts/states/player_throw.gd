class_name PlayerThrow extends PlayerState


var grid_position : Vector2i :
    set(vec):
        grid_position = vec
        GameState.world.throw_cursor.grid_position = grid_position


func enter() -> void:
    super()
    grid_position = GameState.player.grid_position
    GameState.world.throw_cursor.show()
    GameState.display_unit_toggle.emit(false)


func update(inp: StringName) -> Array:
    var world := GameState.world
    var player := GameState.player
    var just_pressed := Input.is_action_just_pressed(inp)
    
    if just_pressed:
        match inp:
            &"c_cancel":
                state_changed.emit("walk")

            &"c_cycle_right":
                player.cycle_selected_unit()

            &"c_cycle_left":
                player.cycle_selected_unit(true)

            # &"c_whistle":
            #     state_changed.emit("whistle")

            &"c_throw":
                if player.selected_unit == Type.Unit.NONE:
                    return [false]
                    
                var tile := world.get_closest_empty_tile(grid_position)
                var unit := player.grab_unit(player.selected_unit)
                
                if tile.type == Type.Tile.VOID and unit.type != Type.Unit.YELLOW:
                    var start := player.grid_position
                    var end := tile.grid_position
                    var cb := func(ctx: DDARC.Context):
                        var res := world.query_tile_at(ctx.grid_position)
                        if res == Type.Tile.WALL or res == Type.Tile.VOID:
                            return true
                        
                    var raycast := DDARC.to_grid_position(start, end, cb)
                    tile = world.get_closest_empty_tile(raycast.cell_path[-2], false)
                    
                
                player.throw_unit(unit, tile)
                
                if player.selected_unit == Type.Unit.NONE:
                    state_changed.emit("walk")
                
                return [true, 1]

    
    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var loops := 3 if Input.is_action_pressed(&"k_shift") else 1
    for _n in loops:    
        var pos := grid_position + dir.vector
        if _in_range(pos):
            grid_position = pos
            continue
        elif dir.is_diagonal:
            var valid := false
            for adir in dir.adjacent:
                var apos := grid_position + adir.vector
                if _in_range(apos):
                    grid_position = apos
                    valid = true
                    break
            if not valid: break
    
    return [false]


func exit() -> void:
    GameState.world.throw_cursor.hide()
    super()


