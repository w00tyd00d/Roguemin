@tool

class_name MainBaseBlueprint extends RoomBlueprint


func _run_context_procedures(world: World, start: Vector2i) -> void:
    world.start_position = context_positions[0][0] + start

    for pos: Vector2i in context_positions[1]:
        var dpos := start + pos
        world.set_glyph(dpos, Glyph.UNIT_SUMMON_TARGET)
        world.unit_summon_targets.append(dpos)

    for pos in context_positions[2]:
        # SET UP ONION
        pass

    var ship_pos : Vector2i = context_positions[3][0] + start
    var ship_size := Vector2i(4, 6)
    for y in ship_size.y+1:
        for x in ship_size.x+1:
            var tile := world.get_tile(ship_pos + Vector2i(x,y))
            tile.type = Type.Tile.WALL
            Tag.add(tile, Tags.UNIT_SHIP)

    world.unit_ship_position = ship_pos + ship_size / 2

    var flag_pos : Vector2i = context_positions[4][0] + start
    world.salvage_return_position = flag_pos
    world.set_glyph(flag_pos, Glyph.new(0, Vector2(19,3)))
    for pos in Util.get_square_around_pos(flag_pos, 15, true):
        if pos == flag_pos: continue
        world.set_glyph(pos, Glyph.GRASS)
