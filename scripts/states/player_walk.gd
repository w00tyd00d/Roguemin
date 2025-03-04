class_name PlayerWalk extends PlayerState


func enter():
    super()


func update(inp: StringName) -> Array:
    var just_pressed := Input.is_action_just_pressed(inp)
    
    if just_pressed:
        ## Add matching buttons to switch to different states
        match inp:
            # &"c_use_key":
            #     print("USING KEY")
            #     state_changed.emit("unlock")
            #     return [false]
            &"c_wait":
                print("WE'RE WAITING")
                return [true, 4]
            # &"c_interact":
            #     print("INTERACTING")
            #     state_changed.emit("interact")
            #     return [false]
            # &"c_attack":
            #     print("ATTACKING")
            #     state_changed.emit("attack")
            #     return [false]
            # &"c_toggle_tool":
            #     var inventory := player.components.inventory as InventoryComponent
            #     var item := inventory.get_equipped_item("tool")
            #     if item:
            #         item.components.tool.toggle()
            #     return [false] # handled in tool component
            # &"c_cancel":
            #     return [false]
    
    var dir := Direction.by_pattern(inp)
    if not dir: return [false]

    var world := GameState.world
    var player := GameState.player
    var tile := player.current_tile
    
    var dest := tile.get_neighbor(dir)
    var res := world.query_tile(dest)
    
    match res:
        Type.Tile.GRASS: player.move_to(dest)
        _: return [false]
    
    # match res:
    #     maze.DOOR:
    #         if not just_pressed:
    #             return [false]
    #         var door: MazeDoor = cell.walls[_direction.name]
    #         door.attempt_to_open(player)
    #         player.stop_movement(true)
    #     maze.PATH, maze.EXIT:
    #         print("WE'RE MOVING!")
    #         player.move_to(dest_cell)
    #     maze.ENEMY:
    #         if not just_pressed:
    #             return [false]
    #         player.components.combat.attack_toward(dest_cell)
    #         player.stop_movement(true)
    #     _:
    #         return [false]
    
    return [true, 4]
