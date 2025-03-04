extends Node

## The main turn manager for the game.


func process_turns(time_units: int) -> void:
    if not GameState.world: return

    var units := get_tree().get_nodes_in_group(&"units")
    var entities := get_tree().get_nodes_in_group(&"entities")

    GameState.world.time += time_units
    var world_time := GameState.world.time

    for unit: Unit in units:
        if unit.time < GameState.world.time:
            unit.update_time(world_time)
