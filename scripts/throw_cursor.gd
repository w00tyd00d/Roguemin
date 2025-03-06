extends Node2D

var grid_position : Vector2i :
    set(vec):
        grid_position = vec
        position = vec * Globals.TILE_SIZE

var current_tile : Tile :
    get: return GameState.world.get_tile(grid_position)

@onready var layer := $Cursor as TileMapLayer


func _process(_dt) -> void:
    layer.visible = not Util.glyph_blinking()

