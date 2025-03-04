class_name PlayerThrow extends PlayerState


var selected_type := Type.Unit.RED

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
                pass
            &"c_cycle_left":
                pass
            &"c_whistle":
                state_changed.emit("whistle")
            &"c_throw":
                if selected_type != Type.Unit.NONE:
                    var tile := world.get_closest_empty_tile(grid_position)
                    var unit := player.grab_unit(selected_type)
                    player.throw_unit(unit, tile)
                    return [true, 1]

    
    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var pos := grid_position + dir.vector
    if _in_range(pos):
        grid_position = pos
    elif dir.is_diagonal:
        for adir in dir.adjacent:
            var apos := grid_position + adir.vector
            if _in_range(apos):
                grid_position = apos
                break
    
    return [false]


func exit() -> void:
    GameState.world.throw_cursor.hide()
    super()


