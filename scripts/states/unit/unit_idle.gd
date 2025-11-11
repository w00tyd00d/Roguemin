class_name UnitIdle extends State


func _init():
    name = "unit_idle"


func enter(ent: Entity) -> void:
    var unit := ent as Unit
    
    unit._update_glyph(true)
    player.remove_unit(unit)
    
    super(ent)


func do_action(_ent: Entity) -> Array:
    # Stand still and do nothing
    return [false]


func exit(ent: Entity) -> void:
    var unit := ent as Unit
    unit._update_glyph(false)
    super(ent)
