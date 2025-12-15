class_name UnitFollow extends State


func _init():
    name = "unit_follow"


func enter(ent: Entity) -> void:
    ent.target = player.unit_tether.tail
    player.add_unit(ent)
    super(ent)


func get_cost(ent: Entity) -> int:
    # ALLOW TO BE MODIFIED BY BEING BOOSTED WITH SPICY SPRAY
    # AND RUSH BOOTS!
    var step := DEFAULT_COST
    var dist := Util.chebyshev(ent.grid_position, player.grid_position)
    return step - 20 if dist > 8 else step


func do_action(ent: Entity) -> ActionResult:
    if not player: return result(false)

    var unit := ent as Unit

    if unit.name == "Unit63":
        pass

    var tether := player.unit_tether
    var dest := tether.tail.current_tile

    if not unit._in_range_of_tether():
        # return [false, States.Unit.IDLE]
        return result(false).new_state(States.Unit.IDLE)

    var path := unit.path

    if unit._can_see_tether():
        path = []
        return result(unit.move_towards(dest))

    if (path.is_empty() or
        Util.chebyshev(path[0], dest.grid_position) >= 5 or
        path.size() == 1 and not unit._can_see_position(path[0])):
            # We get the path in reverse to use as a stack
            path = world.astar.get_id_path(dest.grid_position, unit.grid_position)
            unit._broadcast_path()

    if path.is_empty():
        return result(false)

    var dist := Util.chebyshev(unit.grid_position, path[-1])
    
    if dist < 2:
        path.pop_back()
    if not path.is_empty():
        return result(unit.move_towards(world.get_tile(path[-1])))

    return result(false)
