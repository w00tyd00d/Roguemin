class_name PlayerWalk extends PlayerState

var _action_cost : int :
    # ALLOW TO BE MODIFIED BY RUSH BOOTS ITEM!
    get: return Globals.DEFAULT_TURN_COST


func enter():
    super()
    GameState.display_unit_toggle.emit(false)


func update(inp: StringName) -> Array:
    var just_pressed := Input.is_action_just_pressed(inp)

    if just_pressed:
        match inp:
            &"c_whistle":
                state_changed.emit("whistle")
            &"c_throw":
                if world.unit_summon_targets.has(player.grid_position):
                    for unit in player.get_all_units():
                        unit.go_home()
                elif player.unit_count > 0:
                    state_changed.emit("throw")
            &"c_dismiss":
                for unit in player.get_all_units():
                    unit.dismiss()
                return [true, _action_cost]
            &"c_cycle_right":
                player.cycle_selected_unit()
            &"c_cycle_left":
                player.cycle_selected_unit(true)
            &"c_survey":
                state_changed.emit("survey")
                return [false]

    if inp == &"c_wait":
        return [true, _action_cost]

    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var tile := player.current_tile

    var dest := tile.get_neighbor(dir)
    var res := world.query_tile(dest)

    match res:
        Type.Tile.GRASS: player.move_to(dest)
        Type.Tile.UNIT:
            for unit in dest.get_all_units():
                unit.move_to(tile)
                unit.join_squad()
            player.move_to(dest)
        _: return [false]

    return [true, _action_cost]
