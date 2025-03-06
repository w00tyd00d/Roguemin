class_name PlayerWalk extends PlayerState


func enter():
    super()
    GameState.display_unit_toggle.emit(false)


func update(inp: StringName) -> Array:
    var player := GameState.player
    var world := GameState.world
    var just_pressed := Input.is_action_just_pressed(inp)
    
    if just_pressed:
        match inp:
            &"c_whistle":
                print("WHISTLE STATE!")
                state_changed.emit("whistle")
            &"c_throw":
                if world.unit_summon_targets.has(player.grid_position):
                    for unit in player.get_all_units():
                        unit.go_home()
                elif player.unit_count > 0:
                    print("WE'RE THROWING, DUDE")
                    state_changed.emit("throw")
            &"c_dismiss":
                for unit in player.get_all_units():
                    unit.go_idle()
                return [true, 4]
            &"c_cycle_right":
                player.cycle_selected_unit()
            &"c_cycle_left":
                player.cycle_selected_unit(true)
            &"c_wait":
                print("WE'RE WAITING")
                return [true, 4]

    
    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var tile := player.current_tile
    
    var dest := tile.get_neighbor(dir)
    var res := world.query_tile(dest)
    
    match res:
        Type.Tile.GRASS: player.move_to(dest)
        Type.Tile.ENTITY:
            if dest.has_entities: return [false]
            for unit in dest.get_all_units():
                unit.move_to(tile)
                unit.join_squad()
            player.move_to(dest)
        _: return [false]
    
    return [true, 4]
