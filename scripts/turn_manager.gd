extends Node

## The main turn manager for the game.

signal update_debug_time(time: int)


func process_turns(time_units: int) -> void:
    if not GameState.world: return

    var units := get_tree().get_nodes_in_group(&"units")
    var entities := get_tree().get_nodes_in_group(&"entities")

    GameState.world.time += time_units
    var world_time := GameState.world.time

    var _start_time := Time.get_ticks_msec()
    for unit: Unit in units:
        if unit.time < GameState.world.time:
            unit.update_time(world_time)

    update_debug_time.emit(Time.get_ticks_msec() - _start_time)