class_name WorldPopulator extends RefCounted

## The class responsible for populating the world instance with entities.

var RNG := GameState.RNG 


func generate_enemies(world: World) -> void:
    # Place Spotty Red enemy at specific location for now
    var pos := world.get_chunk(Vector2i(2,1)).center

    world.spawn_entity(SpottyRed, pos)


func generate_treasure(world: World) -> void:
    var treasure : Treasure
    for n in 3:
        var attempts := 0
        treasure = LargeTreasure.create()
        while attempts < 10:
            var rx := RNG.randi_range(0, world.size.x * Globals.CHUNK_SIZE.x)
            var ry := RNG.randi_range(0, world.size.y * Globals.CHUNK_SIZE.y)
            if not _check_for_entity_collision(world, treasure, Vector2i(rx, ry)):
                world.spawn_entity(LargeTreasure, Vector2i(rx, ry))
            attempts += 1
    treasure.queue_free()

    for n in 5:
        var attempts := 0
        treasure = MediumTreasure.create()
        while attempts < 10:
            var rx := RNG.randi_range(0, world.size.x * Globals.CHUNK_SIZE.x)
            var ry := RNG.randi_range(0, world.size.y * Globals.CHUNK_SIZE.y)
            if not _check_for_entity_collision(world, treasure, Vector2i(rx, ry)):
                world.spawn_entity(MediumTreasure, Vector2i(rx, ry))
                break
            attempts += 1
    treasure.queue_free()

    for n in 10:
        var attempts := 0
        treasure = SmallTreasure.create()
        while attempts < 10:
            var rx := RNG.randi_range(0, world.size.x * Globals.CHUNK_SIZE.x)
            var ry := RNG.randi_range(0, world.size.y * Globals.CHUNK_SIZE.y)
            if not _check_for_entity_collision(world, treasure, Vector2i(rx, ry)):
                world.spawn_entity(SmallTreasure, Vector2i(rx, ry))
                break
            attempts += 1
    treasure.queue_free()


func _check_for_entity_collision(world: World, ent: MultiTileEntity, pos: Vector2i) -> bool:
    for vec: Vector2i in ent.get_used_cells():
        var dpos := vec + pos
        var tile := world.get_tile(dpos)
        if not tile: return true
        var glyph := world.get_glyph(dpos)
        if (not glyph.matches(Glyph.NONE) and
            not glyph.matches(Glyph.GRASS) and
            not glyph.matches(Glyph.SHRUB)):
                return true
        if tile._entities.size() > 1:
            return true
    return false