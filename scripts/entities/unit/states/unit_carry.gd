class_name UnitCarry extends State


func _init():
    name = "unit_carry"


func enter(ent: Entity) -> void:
    player.remove_unit(ent)
    super(ent)


func do_action(ent: Entity) -> ActionResult:
    var unit := _unit(ent)
    
    if not unit.held_object:
        if unit.target.is_latch_position(unit.grid_position):
            unit.grab_object(unit.target)
            return result(false)
        return result(unit.move_towards(unit.target.current_tile))
    
    return result(false)


func exit(ent: Entity) -> void:
    _unit(ent).drop_object()
    super(ent)
