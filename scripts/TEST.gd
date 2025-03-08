extends TileMapLayer

var RNG := GameState.RNG

func _ready() -> void:
    var pattern1 = tile_set.get_pattern(0)
    var pattern2 = tile_set.get_pattern(1)

    _draw_path(self, Vector2i(0,0), Vector2i(1,0))


func _draw_path(layer: TileMapLayer, vec1: Vector2i, vec2: Vector2i) -> void:
    var wall_pattern := tile_set.get_pattern(0)
    var path_pattern := tile_set.get_pattern(1)

    var wall_offset := Vector2i(4,4)
    var path_offset := Vector2i(5,5)

    var path := Util.get_bresenham_line(vec1 * Globals.CHUNK_SIZE.x, vec2 * Globals.CHUNK_SIZE.y)
    var size := path.size()

    var half := Globals.CHUNK_HALF

    for i in size+2:
        if i < size:
            set_pattern(path[i], wall_pattern)
            var center := path[i] + half + wall_offset
            var vecs := Util.get_square_around_pos(center, 17)
            # for pos in vecs:
            #     set_tile_type(pos, Type.Tile.WALL)
            #     astar.set_point_solid(pos, true)

        if i >= 2:
            layer.set_pattern(path[i-2] + Vector2i.ONE, path_pattern)
            var center := path[i-2] + half + path_offset
            var vecs := Util.get_square_around_pos(center, 15, true)
            for pos in vecs:
                var choices := [Glyph.GRASS, Glyph.SHRUB]
                var weights := PackedFloat32Array([1, .01])
                var idx := RNG.rand_weighted(weights)
                # layer.set_glyph(pos, choices[idx])
                # layer.set_tile_type(pos, Type.Tile.GRASS)