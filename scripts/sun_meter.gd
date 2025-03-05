extends DualMapLayer

const TOTAL_LENGTH := 60

@warning_ignore("integer_division")
const INTERVAL := Globals.TIME_LIMIT / TOTAL_LENGTH


func _ready() -> void:
    GameState.update_sun_meter.connect(update)


func reset():
    grid_position = Vector2i()


func update(time: int) -> void:
    @warning_ignore("integer_division")
    var x := time / INTERVAL
    grid_position = Vector2i(x, 0)