class_name PlayerWhistle extends PlayerState


var grid_position : Vector2i :
    set(pos):
        grid_position = pos
        _update_preview()

var whistle_level := 1 :
    set(n):
        n = clamp(n, Globals.WHISTLE_MIN_SIZE, Globals.WHISTLE_MAX_SIZE)
        whistle_level = n
        _update_preview()


func enter() -> void:
    super()
    grid_position = GameState.player.grid_position
    GameState.display_unit_toggle.emit(true)


func update(inp: StringName) -> Array:
    var world := GameState.world
    var player := GameState.player
    var just_pressed := Input.is_action_just_pressed(inp)
    
    if just_pressed:
        match inp:
            &"c_cancel":
                state_changed.emit("walk")
            &"c_cycle_right":
                whistle_level += 1
            &"c_cycle_left":
                whistle_level -= 1
            &"c_toggle_red":
                player.toggle_unit(Type.Unit.RED)
            &"c_toggle_yellow":
                player.toggle_unit(Type.Unit.YELLOW)
            &"c_toggle_blue":
                player.toggle_unit(Type.Unit.BLUE)
            &"c_whistle", &"c_throw":
                world.whistle.activate(whistle_level)
                for pos in _get_whistle_area():
                    world.get_tile(pos).whistled()
                
                state_changed.emit("walk")
                return [true, ceil(whistle_level / 2.0)]
    
    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var pos := grid_position + dir.vector
    if _in_range(pos):
        grid_position = pos
    
    return [false]


func exit() -> void:
    GameState.world.whistle.cancel_preview()
    super()


func _update_preview() -> void:
    GameState.world.whistle.preview(grid_position, whistle_level)


func _get_whistle_area() -> Array[Vector2i]:
    var length := (whistle_level-1) * 2 + 1
    return Util.get_square_around_pos(grid_position, length, true)