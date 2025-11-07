class_name UnitFollow extends State


func _init():
    name = "unit_follow"


func enter(ent: Entity) -> void:
    ent.target = player.unit_tether.tail
    player.add_unit(ent)
    super(ent)


## Attempts to perform an action to consume energy
func do_action(ent: Entity) -> Array:
    if not player: return [false]

    var unit := ent as Unit

    if unit.name == "Unit04":
        pass

    var tether := player.unit_tether
    var dest := tether.tail.current_tile

    if not unit._in_range_of_tether():
        unit._go_idle()
        return [false]

    var path := unit.path

    if unit._can_see_tether():
        path = []
        return [unit.move_towards(dest)]

    if (path.is_empty() or
        Util.chebyshev_distance(path[0], dest.grid_position) >= 5 or
        path.size() == 1 and not unit._can_see_destination(path[0])):
            # We get the path in reverse to use as a stack
            path = world.astar.get_id_path(dest.grid_position, unit.grid_position)
            unit._broadcast_path()

    if path.is_empty():
        return [false]

    var dist := Util.chebyshev_distance(unit.grid_position, path[-1])
    
    if dist < 2:
        path.pop_back()
    if not path.is_empty():
        return [unit.move_towards(world.get_tile(path[-1]))]

    return [false]


# func exit(ent: Entity) -> void:
#     pass

