extends Node2D

var grid_position : Vector2i :
    set(vec):
        grid_position = vec
        position = vec * Globals.TILE_SIZE

var current_tile : Tile :
    get: 
        if GameState.world:
            return GameState.world.get_tile(grid_position)
        return null

@onready var layer := $Cursor as TileMapLayer


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_dt) -> void:
    layer.visible = not GameState.glyph_blinking()

