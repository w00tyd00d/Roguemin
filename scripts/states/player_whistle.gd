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
            &"c_whistle":
                world.whistle.activate(whistle_level)
                state_changed.emit("walk")
                return [true, ceil(whistle_level / 2.0)]
    
    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var pos := grid_position + dir.vector
    
    if Util.chebyshev_distance(player.grid_position, pos) <= Globals.WHISTLE_MAX_RANGE:
        grid_position = pos
    
    return [false]


func exit() -> void:
    GameState.world.whistle.cancel_preview()
    super()


func _update_preview() -> void:
    GameState.world.whistle.preview(grid_position, whistle_level)