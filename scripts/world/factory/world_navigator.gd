class_name WorldNavigator extends RefCounted

## The class responsible for pre-baking navigation information into the world.

var _wall_tiles : Array[Tile] = []


func run(world: World) -> void:
    generate_flow_field(world)
    generate_wall_dijkstra_map(world)


func generate_flow_field(world: World) -> void:
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
                    _wall_tiles.append(tile)
                    continue

                var dir := Direction.by_delta(tile.grid_position, nbr.grid_position)
                var cost := 7 if dir.is_diagonal else 5
                var val := tile._flow_field_value + cost

                if nbr._flow_field_value > val:
                    nbr._flow_field_value = val
                    nbr._flow_field_vector = nbr._get_best_flow_field_vector()
                    new_tiles.append(nbr)

        tiles = new_tiles


func generate_wall_dijkstra_map(_world: World) -> void:
    var hist := {}
    var tiles := _wall_tiles
    var step := 1

    while not tiles.is_empty() and step < 7:
        var new_tiles : Array[Tile] = []
        for tile in tiles:
            for nbr in tile.get_all_neighbors():
                if hist.has(nbr) or nbr.type == Type.Tile.VOID:
                    continue
                nbr._distance_from_wall = step
                new_tiles.append(nbr)
                hist[nbr] = true

        tiles = new_tiles
        step += 1