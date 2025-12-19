class_name QuickInfo extends Control

@export var enemy: Enemy

var grid_position : Vector2i :
    set(vec):
        grid_position = vec
        position = grid_position * Globals.TILE_SIZE

@onready var health_lbl := $Health as Label
@onready var health_bg := $Health/BackgroundLayer as TileMapLayer

@onready var direction_lbl := $Direction as Label
@onready var direction_bg := $Direction/BackgroundLayer as TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    hide()
    GameState.display_quick_info.connect(func(val: bool):
        if val:
            update()
            show()
            return
        hide()
    )

    enemy.health_changed.connect(_update_health)
    enemy.facing_changed.connect(_update_direction)


func update():
    _update_health()
    _update_direction()


func set_glyph(layer: TileMapLayer, pos: Vector2i, glyph: Glyph) -> void:
    layer.set_cell(
        pos,
        glyph.source,
        glyph.atlas_pos,
        glyph.alt_tile_id)


func _update_health():
    var perc := enemy.get_health_percent_num()
    var health := "{0}%{1}".format([perc, " " if perc < 10 else ""])
    
    health_lbl.text = health

    set_glyph(health_bg, Vector2i(0,0), Glyph.NONE if perc < 100 else Glyph.BLACK)
    set_glyph(health_bg, Vector2i(3,0), Glyph.NONE if perc < 10 else Glyph.BLACK)


func _update_direction():
    var key: Dictionary[Direction, String] = {
        Direction.north: "N",
        Direction.south: "S",
        Direction.west: "W",
        Direction.east: "E",
        Direction.northwest: "NW",
        Direction.northeast: "NE",
        Direction.southwest: "SW",
        Direction.southeast: "SE"
    }
    var dir := key[enemy.facing]

    direction_lbl.text = "{0}".format([dir])

    set_glyph(direction_bg, Vector2i(0,0), Glyph.BLACK if enemy.facing.is_diagonal else Glyph.NONE)
