class_name PlayerSurvey extends PlayerState


func enter() -> void:
    super()
    GameState.display_survey_indicator.emit(true)


func update(inp: StringName) -> Array:
    var player := GameState.player
    var camera := player.camera
    var just_pressed := Input.is_action_just_pressed(inp)
    
    if just_pressed:
        match inp:
            &"c_cancel":
                camera.align()
                state_changed.emit("walk")
                return [false]
    
    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var loops := 3 if Input.is_action_pressed(&"k_shift") else 1
    for _n in loops:    
        camera.offset += Vector2(dir.vector * Globals.TILE_SIZE)
    
    return [false]


func exit() -> void:
    GameState.player.camera.offset = Vector2()
    GameState.display_survey_indicator.emit(false)
    super()