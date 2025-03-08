extends CanvasLayer

## The heads up display for the game.

@onready var sun_meter := $SunMeter as DualMapLayer

@onready var player_name := $PlayerName as Label
@onready var player_health := $PlayerHealth as Label
@onready var selected_unit := $SelectedUnit as Label
@onready var squad_count := $SquadCount as Label
@onready var field_count := $FieldCount as Label
@onready var total_count := $TotalCount as Label

@onready var info_box := $InfoBox as RichTextLabel

@onready var money_value := $MoneyValue as Label
@onready var quota_value := $QuotaValue as Label
@onready var quota_limit := $QuotaLimit as Label

@onready var day_count := $DayCount as Label
@onready var quota_count := $QuotaCount as Label

@onready var debug_time := $DebugTime as Label

func _ready() -> void:
    GameState.toggle_hud.connect(func(val: bool):
        visible = val
    )
    
    GameState.update_player_health.connect(func(val):
        player_health.text = "{0}%".format([val])
    )
    
    GameState.update_selected_unit.connect(_update_selected_unit)
    GameState.update_squad_count.connect(_update_squad_count)
    GameState.update_field_count.connect(_update_field_count)
    GameState.update_total_count.connect(_update_total_count)

    GameState.update_info_box.connect(_update_info_box)

    GameState.update_money_value.connect(func(val):
        money_value.text = str(val)
    )

    # TurnManager.update_debug_time.connect(func(time: int):
    #     debug_time.text = "Proc: {0}ms".format([time])
    # )


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


func _update_info_box(ent: Entity) -> void:
    if not ent:
        info_box.text = ""
        return
    
    const ENEMY_STRING := "[color=red]{0}[/color]\n\n{1}%"
    const TREASURE_STRING := "[color=f6af09]{0}[/color]\n\n[color=f6af09]$[/color]{1}"

    if ent is Enemy:
        var health := ent.get_health_percent() as float
        info_box.text = ENEMY_STRING.format([ent.entity_name, ceili(health * 100)])

    elif ent is Treasure:
        var value := ent.money_value as int
        info_box.text = TREASURE_STRING.format([ent.entity_name, value])