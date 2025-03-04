extends Node2D

var grid_position : Vector2i :
    set(vec):
        grid_position = vec
        position = vec * Globals.TILE_SIZE

@onready var layer := $Cursor as TileMapLayer


func _process(_dt) -> void:
    layer.visible = not Util.glyph_blinking()

