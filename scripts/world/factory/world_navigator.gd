class_name WorldNavigator extends RefCounted

## The class responsible for pre-baking navigation information into the world.

const ON_PATH_COST := 4
const OFF_PATH_COST := 5
const DIAGONAL_COST := 7

const OFF_PATH_PENALTY := 50

const WALL_STEP_LIMIT := 7

var _wall_tiles : Dictionary[Tile, int] = {}


func run(world: World) -> void:
    _wall_tiles = {}
    await generate_salvage_paths(world)
    generate_navigation_fields(world)


func generate_salvage_paths(world: World) -> void:
    while not world.salvage_path_queue.is_empty():
        var path : Array = world.salvage_path_queue.pop_back()
        world.add_to_salvage_path(path[0], path[1])
        await GameState.get_tree().process_frame


func generate_navigation_fields(world: World) -> void:
    var start := world.salvage_return_tile

    start.flow_field_value = 0

    var hist := {}
    var tiles : Array[Tile] = [start]

    while not tiles.is_empty():
        var new_tiles : Array[Tile] = []

        for tile in tiles:
            hist[tile] = true
            for nbr in tile.get_all_neighbors():
                if hist.has(nbr) or nbr.type == Type.Tile.VOID:
                    continue

                if nbr.type == Type.Tile.WALL:
                    _wall_tiles[nbr] = 0
                    continue

                var dir := Direction.by_delta(tile.grid_position, nbr.grid_position)
                var cost := 7 if dir.is_diagonal else 5
                var val := tile.flow_field_value + cost

                if not world.salvage_path_tiles.has(nbr):
                    val += OFF_PATH_PENALTY

                if nbr.flow_field_value > val:
                    nbr.flow_field_value = val
                    new_tiles.append(nbr)

        tiles = new_tiles
        
        # Run an iteration of the wall dijkstra map generation
        _iterate_wall_dijkstra_map(world)

        await GameState.get_tree().process_frame


func _iterate_wall_dijkstra_map(_world: World) -> void:
    var new_tiles : Dictionary[Tile, int] = {}

    for tile in _wall_tiles:
        var step := _wall_tiles[tile]
        if step >= WALL_STEP_LIMIT: continue
        for nbr in tile.get_all_neighbors():
            if nbr.type == Type.Tile.VOID: continue
            if nbr.set_distance_from_wall(step + 1):
                new_tiles[nbr] = step + 1

    _wall_tiles = new_tiles

