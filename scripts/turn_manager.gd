extends Node

## The main turn manager for the game.

signal update_debug_time(time: int)


func process_turns(time_units: int) -> void:
    if not GameState.world: return

    var units := get_tree().get_nodes_in_group(&"units")
    var entities := get_tree().get_nodes_in_group(&"entities")

    GameState.world.time += time_units
    # var world_time := GameState.world.time

    # var _start_time := Time.get_ticks_msec()

    var unit_queue : Array[Unit] = []
    var entity_queue : Array[Entity] = []

    for unit: Unit in units:
        if unit.time < GameState.world.time and unit.update():
            unit_queue.append(unit)
    
    while not unit_queue.is_empty():
        var unit : Unit = unit_queue.pop_front()
        if unit.update():
            unit_queue.append(unit)

    for entity: MultiTileEntity in entities:
        if entity.time < GameState.world.time:
            entity.update()
    
    while not entity_queue.is_empty():
        var entity : Unit = entity_queue.pop_front()
        if entity.update():
            entity_queue.append(entity)

    # update_debug_time.emit(Time.get_ticks_msec() - _start_time)
