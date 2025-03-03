class_name Unit extends Entity

## The entity the [Player] controls to do tasks for them.

enum Type { RED, YELLOW, BLUE }

enum State { 
    IDLE,
    FOLLOWING,
    ATTACKING,
    CARRYING
}


## The current type of the unit.
var type : Type

## Returns if the unit has been upgraded or not.
var upgraded : bool

## The current state of the unit.
var state := State.FOLLOWING

## The current target of the unit.
var target : Entity


func reset() -> void:
    hide()
    grid_position = Vector2()
    if GameState.world:
        var count := GameState.world.unit_count
        GameState.world.unit_count = maxi(count-1, 0)


func spawn(pos: Vector2i, _type: Type, _upgraded := false) -> void:
    type = _type
    upgraded = _upgraded
    _update_glyph()
    
    grid_position = pos
    show()


func upgrade() -> void:
    upgraded = true
    _update_glyph()


func die() -> void:
    # SETUP DEATH ANIMATION
    reset()


func _update_glyph() -> void:
    match type:
        Type.RED:
            if upgraded: set_glyph(Vector2(), Glyph.UNIT_RED_LARGE)
            else: set_glyph(Vector2(), Glyph.UNIT_RED_SMALL)
        Type.YELLOW:
            if upgraded: set_glyph(Vector2(), Glyph.UNIT_YELLOW_LARGE)
            else: set_glyph(Vector2(), Glyph.UNIT_YELLOW_SMALL)
        Type.BLUE:
            if upgraded: set_glyph(Vector2(), Glyph.UNIT_BLUE_LARGE)
            else: set_glyph(Vector2(), Glyph.UNIT_BLUE_SMALL)