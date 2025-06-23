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

    # var waves : Array[Wave] = []
    # waves.append(Wave.new(world, start, Direction.north))
    # waves.append(Wave.new(world, start, Direction.south))
    
    # while not waves.is_empty():
    #     var new_waves : Array[Wave] = []
        
    #     for wave in waves:
    #         var res := wave.spread()
    #         if res[0]:
    #             new_waves.append(wave)

    #         for wall in res[1]:
    #             _wall_tiles[wall] = 0
        
    #         new_waves.append_array(res[2])

    #     waves = new_waves

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
                    # _wall_tiles[nbr] = 0
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
        # _iterate_wall_dijkstra_map(world)
        
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


# class Wave:
#     var world : World
#     # var grid_position : Vector2i
#     # var value : int
#     var origin : Vector2i
#     var direction : Direction

#     var tiles : Array[Tile] = []
#     # var on_path := false

#     func _init(_world: World, tile: Tile, dir: Direction) -> void:
#         world = _world
#         tiles = [tile]
#         direction = dir
#         origin = tile.grid_position

    
#     func fork(tile: Tile) -> Array[Wave]:
#         var res : Array[Wave] = []
        
#         # We only need to worry about any paths to go down since the chunk
#         # will continue to be filed from the wave that entered it
#         for dir in Direction.get_cardinal():
#             var has_edge := tile.chunk.has_edge(dir)
#             var nbr := tile.get_neighbor(dir)
#             var val := tile.flow_field_value
#             # if _is_valid(nbr, val + ON_PATH_COST) and has_edge:
#             if has_edge:
#                 res.append(Wave.new(world, nbr, dir))
        
#         return res
    
#     func spread() -> Array:
#         var new_tiles : Array[Tile] = []
#         var walls : Array[Tile] = []
#         var waves : Array[Wave] = []
        
#         for tile in tiles:
#             var nbr : Tile
#             var val := tile.flow_field_value

#             for dir in direction.orthagonal:
#                 nbr = tile.get_neighbor(dir)
#                 if _is_valid(nbr, val + OFF_PATH_COST):
#                     nbr.flow_field_value = val + OFF_PATH_COST
#                     new_tiles.append(nbr)
#                 else:
#                     walls.append(nbr)
            
#             for dir in direction.adjacent:
#                 nbr = tile.get_neighbor(dir)
#                 if _is_valid(nbr, val + DIAGONAL_COST):
#                     nbr.flow_field_value = val + DIAGONAL_COST
#                     new_tiles.append(nbr)
#                 else:
#                     walls.append(nbr)

#             nbr = tile.get_neighbor(direction)
#             var move_cost = ON_PATH_COST if _is_on_path(nbr) else OFF_PATH_COST
            
#             if nbr.chunk.center == nbr.grid_position:
#                 waves = fork(nbr)
            
#             if _is_valid(nbr, val + move_cost):
#                 nbr.flow_field_value = val + move_cost
#                 new_tiles.append(nbr)

#         tiles = new_tiles

#         return [not tiles.is_empty(), walls, waves]
    
#     func _is_valid(nbr: Tile, val: int) -> bool:
#         return nbr.type != Type.Tile.WALL and nbr.flow_field_value > val
        
#     func _is_on_path(nbr: Tile) -> bool:
#         if direction.is_vertical:
#             return nbr.grid_position.x == origin.x
#         return nbr.grid_position.y == origin.y

