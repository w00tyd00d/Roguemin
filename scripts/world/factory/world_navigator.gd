class_name WorldNavigator extends RefCounted

## The class responsible for pre-baking navigation information into the world.

const WALL_STEP_LIMIT := 7

var _wall_tiles : Dictionary[Tile, int] = {}


func run(world: World) -> void:
    _wall_tiles = {}
    generate_navigation_fields(world)


func generate_navigation_fields(world: World) -> void:
    var start := world.salvage_return_tile

    start._flow_field_value = 0

    var hist := {}
    var tiles : Array[Tile] = [start]

    while not tiles.is_empty():
        var new_tiles : Array[Tile] = []

        for tile in tiles:
            hist[tile] = true
            for nbr in tile.get_all_neighbors():
                if hist.has(nbr) or nbr.type == Type.Tile.VOID:
                    continue

                if tile.type == Type.Tile.WALL:
                    _wall_tiles[tile] = 0
                    continue

                var dir := Direction.by_delta(tile.grid_position, nbr.grid_position)
                var cost := 7 if dir.is_diagonal else 5
                var val := tile._flow_field_value + cost

                if nbr._flow_field_value > val:
                    nbr._flow_field_value = val
                    nbr._flow_field_vector = nbr._get_best_flow_field_vector()
                    new_tiles.append(nbr)

        tiles = new_tiles

        # Run an iteration of the wall dijkstra map generation
        _iterate_wall_dijkstra_map(world)
        
        # Wait until the next frame to run another iteration
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