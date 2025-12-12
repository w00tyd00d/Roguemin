class_name UnitCarry extends State


func _init():
    name = "unit_carry"


func enter(ent: Entity) -> void:
    player.remove_unit(ent)
    super(ent)


func do_action(ent: Entity) -> ActionResult:
    if not ent.held_object:
        if ent.target.is_latch_position(ent.grid_position):
            ent.grab_object(ent.target)
            return result(false)
        return result(ent.move_towards(ent.target.current_tile))
    
    return result(false)


func exit(ent: Entity) -> void:
    ent.drop_object()
    super(ent)

