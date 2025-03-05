@tool

extends RoomBlueprint


func run_context_procedures(world: World, start: Vector2i) -> void:
    world.start_position = context_positions[0][0]

    world.unit_summon_targets = context_positions[1]
    for pos: Vector2i in context_positions[1]:
        var dpos := start + pos
        world.set_glyph(dpos, Glyph.UNIT_SUMMON_TARGET)

    for pos in context_positions[2]:
        # SET UP ONION
        pass

    # SET UP AREA BETWEEN 3 AND 4 AS UNWALKABLE
    var pos : Vector2i = context_positions[4][0] + start
    world.set_glyph(pos, Glyph.new(0, Vector2(19,3)))
