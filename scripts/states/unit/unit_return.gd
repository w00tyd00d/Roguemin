class_name UnitReturn extends State


func _init():
    name = "unit_return"


func enter(ent: Entity) -> void:
    ent.target = world.unit_ship_tile
    super(ent)


func do_action(ent: Entity) -> ActionResult:
    return result(ent.move_towards(world.unit_ship_tile))
