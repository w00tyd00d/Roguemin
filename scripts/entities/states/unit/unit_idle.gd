class_name UnitIdle extends State


func _init():
    name = "unit_idle"


func enter(ent: Entity) -> void:
    _update_glyph(ent, true)
    player.remove_unit(ent)
    super(ent)


func do_action(_ent: Entity) -> Array:
    # Stand still and do nothing
    return [false]


func exit(ent: Entity) -> void:
    _update_glyph(ent, false)
    super(ent)


func _update_glyph(ent: Entity, going_idle: bool) -> void:
    var unit := ent as Unit
    match unit.type:
        Type.Unit.RED:
            if unit.upgraded:
                if going_idle: unit.set_glyph(Vector2(), Glyph.UNIT_RED_LARGE_IDLE)
                else: unit.set_glyph(Vector2(), Glyph.UNIT_RED_LARGE)
            elif going_idle: unit.set_glyph(Vector2(), Glyph.UNIT_RED_SMALL_IDLE)
            else: unit.set_glyph(Vector2(), Glyph.UNIT_RED_SMALL)
        Type.Unit.YELLOW:
            if unit.upgraded:
                if going_idle: unit.set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE_IDLE)
                else: unit.set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE)
            elif going_idle: unit.set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL_IDLE)
            else: unit.set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL)
        Type.Unit.BLUE:
            if unit.upgraded:
                if going_idle: unit.set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE_IDLE)
                else: unit.set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE)
            elif going_idle: unit.set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL_IDLE)
            else: unit.set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL)
