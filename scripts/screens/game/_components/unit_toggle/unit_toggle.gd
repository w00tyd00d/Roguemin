class_name UnitToggle extends ColorRect

const ACTIVE_CHAR := "■"
const INACTIVE_CHAR := "□"

const RED_STRING := "1:{0} Red"
const YELLOW_STRING := "2:{0} Yellow"
const BLUE_STRING := "3:{0} Blue"

var labels : Dictionary

@onready var red_label := $RedLabel as Label
@onready var yellow_label := $YellowLabel as Label
@onready var blue_label := $BlueLabel as Label


func _ready() -> void:
    GameState.display_unit_toggle.connect(func(val: bool):
        visible = val
    )

    GameState.update_unit_toggle.connect(_update)

    labels = {
        Type.Unit.RED: [red_label, RED_STRING],
        Type.Unit.YELLOW: [yellow_label, YELLOW_STRING],
        Type.Unit.BLUE: [blue_label, BLUE_STRING]
    }


func _update(data: Dictionary) -> void:
    for key in data:
        var val := data[key] as bool
        var lbl := labels[key][0] as Label
        var txt := labels[key][1] as String

        lbl.text = txt.format([ACTIVE_CHAR if val else INACTIVE_CHAR])
