class_name DualMapLayer extends TileMapLayer

## Base texture object for anything that exists within the world in-game.

## The glyph layer of the sprite. The base layer represents the background of
## the front layer (due to draw order).
@onready var glyph_layer := $GlyphLayer as TileMapLayer


static func create() -> DualMapLayer:
    return preload("res://prefabs/dual_map_layer.tscn").instantiate()


func set_glyph(pos: Vector2i, glyph: Glyph) -> void:
    _set_tile(glyph_layer, pos, glyph)


func get_glyph(pos: Vector2i) -> Glyph:
    return _get_tile(glyph_layer, pos)


func set_background(pos: Vector2i, glyph: Glyph):
    _set_tile(self, pos, glyph)


func get_background(pos: Vector2i):
    return _get_tile(self, pos)


func _set_tile(layer: TileMapLayer, pos: Vector2i, glyph: Glyph) -> void:
    layer.set_cell(
        pos,
        glyph.source,
        glyph.atlas_coordinates,
        glyph.alternative_tile_id)


func _get_tile(layer: TileMapLayer, pos: Vector2i) -> Glyph:
    return Glyph.get_from(layer, pos)