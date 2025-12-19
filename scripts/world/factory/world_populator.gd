class_name WorldPopulator extends RefCounted

## The class responsible for populating the world instance with entities.

var RNG := GameState.RNG

var debug_mode: bool


func run(world: World, debug: bool) -> void:
    debug_mode = debug

    generate_enemies(world)
    generate_treasure(world)


func generate_enemies(world: World) -> void:
    # Place Spotty Red enemy at specific location for now
    var pos: Vector2i
    if debug_mode:
        pos = world.get_chunk(Vector2i(6,4)).center
    else:
        pos = world.get_chunk(Vector2i(2,1)).center

    world.spawn_entity(SpottyRed, pos)


func generate_treasure(world: World) -> void:
    if debug_mode: return
   
    _verify_treasure_placement(world, LargeTreasure, 20)
    _verify_treasure_placement(world, MediumTreasure, 5)
    _verify_treasure_placement(world, SmallTreasure, 10)


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


func _verify_treasure_placement(world: World, cls: GDScript, count: int) -> void:
    var treasure := cls.create() as Treasure
    world.add_child(treasure)

    for n in count:
        var attempts := 0
        while attempts < 10:
            var rx := RNG.randi_range(0, world.size.x * Globals.CHUNK_SIZE.x)
            var ry := RNG.randi_range(0, world.size.y * Globals.CHUNK_SIZE.y)
            if not _check_for_entity_collision(world, treasure, Vector2i(rx, ry)):
                world.spawn_entity(cls, Vector2i(rx, ry))
                break
            attempts += 1

    treasure.queue_free()
