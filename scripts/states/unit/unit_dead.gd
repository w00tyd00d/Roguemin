class_name UnitDead extends State


func _init():
    name = "unit_dead"


func enter(ent: Entity) -> void:
    var unit := ent as Unit
    
    if world:
        unit.target = null
        unit.drop_object()
    
        unit.current_tile.remove_unit(unit)
        player.remove_unit(unit)

        world.unit_count -= 1

        unit.brain.reset()
    
    super(ent)


func exit(ent: Entity) -> void:
    super(ent)

