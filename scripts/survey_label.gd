extends ColorRect

@onready var _accents : Array[Label] = [
    $Accent1,
    $Accent2,
    $Accent3,
    $Accent4,
]

func _ready() -> void:
    GameState.display_survey_indicator.connect(func(state: bool):
        visible = state
    )


func _process(_dt) -> void:
    var idx := int(Time.get_ticks_msec() * 0.002) % 3
    
    for i in 4:
        if i == idx or i == idx + 1:
            _accents[i].show()
        else:
            _accents[i].hide()
    
