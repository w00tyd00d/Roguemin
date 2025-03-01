class_name DualMapLayer extends TileMapLayer

## Base texture object for anything that exists within the world in-game.

## The glyph layer of the sprite. The base layer represents the background of
## the front layer (due to draw order).
@onready var glyph_layer := $GlyphLayer as TileMapLayer

