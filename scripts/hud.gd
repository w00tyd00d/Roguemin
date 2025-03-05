extends CanvasLayer

## The heads up display for the game.

@onready var sun_meter := $SunMeter as DualMapLayer

@onready var player_name := $PlayerName as Label
@onready var player_health := $PlayerHealth as Label
@onready var selected_unit := $SelectedUnit as Label
@onready var squad_count := $SquadCount as Label
@onready var field_count := $FieldCount as Label
@onready var total_count := $TotalCount as Label


func _ready() -> void:
    GameState.update_selected_unit.connect(_update_selected_unit)
    GameState.update_squad_count.connect(_update_squad_count)
    GameState.update_field_count.connect(_update_field_count)
    GameState.update_total_count.connect(_update_total_count)


func _update_selected_unit(type: Type.Unit) -> void:
    var player := GameState.player
    var count := 0 if type == Type.Unit.NONE else player.get_unit_count(type)
    var data := Unit.metadata(type)

    if count == 0 and not type == Type.Unit.NONE:
        player.cycle_selected_unit()
        return

    # FILTER OUT ANY THAT ARE TOO FAR AWAY

    const STRING := "{0} ({1})"
    selected_unit.text = STRING.format([data.name, count])
    selected_unit.self_modulate = data.color


func _update_squad_count(count: int) -> void:
    squad_count.text = "Squad: {0}".format([count])


func _update_field_count(count: int) -> void:
    field_count.text = "Field: {0}".format([count])


func _update_total_count(count: int) -> void:
    total_count.text = "Total: {0}".format([count])
