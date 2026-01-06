@tool
class_name AttackIndicator extends DualMapLayer

# Shorthand
var world : World :
    get: return GameState.world

## The attack shape of this indicator.
@export var attack_type : Type.AttackArea :
    set(type):
        attack_type = type
        if Engine.is_editor_hint():
            update()

## The distance of how big the attack area will be from the origin of the attack
@export_range(0,20,1) var attack_range : float :
    set(n):
        attack_range = n
        if Engine.is_editor_hint():
            update()

## For changing the angle of the attack cone.
## NOTE: For debugging purposes in the editor. Not used in-game.
@export_range(0,1,0.001) var attack_angle: float :
    set(n):
        attack_angle = n
        if Engine.is_editor_hint():
            update()

## The cached positions of the currently targeted area.
var targeted_positions : Array[Vector2i] = []

## Whether the attack indicator is activated or not.
var active := false :
    set(val):
        active = val
        if val:
            process_mode = Node.PROCESS_MODE_ALWAYS
            show()
        else:
            process_mode = Node.PROCESS_MODE_DISABLED
            hide()

func _ready() -> void:
    super()
    process_mode = Node.PROCESS_MODE_DISABLED
    top_level = true # Desyncs transform properties from parent


func _process(_dt: float) -> void:
    if Engine.is_editor_hint():
        return
    
    visible = not GameState.glyph_blinking()


func reset() -> void:
    targeted_positions = []
    clear_glyphs()


func target_position(pos: Vector2i) -> void:
    grid_position = pos
    update()


func target_tile(tile: Tile) -> void:
    target_position(tile.grid_position)
    active = true


func deactivate() -> void:
    active = false


func update() -> void:
    reset()
    match attack_type:
        Type.AttackArea.SQUARE: _set_area()
        Type.AttackArea.CIRCLE: _set_area(true)
        Type.AttackArea.CONE: _set_cone()


func _valid_tile(pos: Vector2i) -> bool:
    if Engine.is_editor_hint():
        return true
    
    match world.query_tile_at(pos):
        Type.Tile.UNIT, Type.Tile.GRASS, Type.Tile.WATER:
            return true
        Type.Tile.ENTITY:
            return world.get_tile(pos).has_player
        _:
            return false


func _set_attack_position(pos: Vector2i) -> void:
    set_glyph(pos, Glyph.ATTACK_FG)
    set_background(pos, Glyph.ATTACK_BG)
    targeted_positions.append(pos + grid_position)


func _set_area(circle := false) -> void:
    var r := attack_range

    for y in range(-r, r+1):
        for x in range(-r, r+1):
            var pos := Vector2i(x,y)
            
            if not _valid_tile(pos + grid_position):
                continue 
            
            if circle:
                var dist := grid_position.distance_squared_to(pos + grid_position)
                if dist > (r + 0.5) * (r + 0.5):
                    continue
            
            _set_attack_position(pos)


func _set_cone() -> void:
    # FIND CLOSEST LATCH POINT TO TARGET
    # FOR NOW JUST GO FROM 0,0
    
    # GET VECTOR TOWARDS DIRECTION OF TARGET
    # ALSO FOR NOW, JUST TARGET RIGHT

    
    _set_attack_position(Vector2())
    
    var debug_cb := func(ctx: DDARC.Context):
        _set_attack_position(ctx.grid_position)

    var default_cb := func(_ctx: DDARC.Context):
        pass

    var callback := debug_cb if Engine.is_editor_hint() else default_cb
    var start_pos := Vector2(0.5, 0.5)
    var aim_vector := Vector2(1,0).rotated(attack_angle * TAU)
    
    for deg in range(-12, 12+1, 3):
        DDARC.by_vector(
            start_pos,
            aim_vector.rotated(deg_to_rad(deg)),
            callback,
            attack_range
        )
    
