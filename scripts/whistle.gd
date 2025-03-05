class_name Whistle extends Node2D

const ANIMATION_TIME := 1.5 # seconds
const ANIMATION_SPEED := 0.05 # seconds

var grid_position : Vector2i :
    set(vec):
        grid_position = vec
        position = vec * Globals.TILE_SIZE

var _key : Array[int] = [2, 4, 7, 10] # layer number, not idx

# Preview variables
var _preview_size := 1 :
    set(n):
        preview_layers[_key[_preview_size-1]-1].hide()
        _preview_size = clampi(n, Globals.WHISTLE_MIN_SIZE, Globals.WHISTLE_MAX_SIZE)

# Animation variables
var _anim_target_size := 0
var _anim_current_size := 0 :
    set(n):
        if _anim_current_size != 0:
            animation_layers[_anim_current_size-1].hide()
        _anim_current_size = n
        if n != 0:
            animation_layers[n-1].show()

var _anim_timer := 0.0
var _anim_time_limit := 0.0
var _acc := 0.0

@onready var cursor := $Cursor as TileMapLayer
@onready var preview_view := $PreviewView as Node2D

@onready var preview_layers : Array[TileMapLayer] = [
    %PreviewLayer1,
    %PreviewLayer2,
    %PreviewLayer3,
    %PreviewLayer4,
    %PreviewLayer5,
    %PreviewLayer6,
    %PreviewLayer7,
    %PreviewLayer8,
    %PreviewLayer9,
    %PreviewLayer10
]

@onready var animation_layers : Array[TileMapLayer] = [
    $AnimationLayer1,
    $AnimationLayer2,
    $AnimationLayer3,
    $AnimationLayer4,
    $AnimationLayer5,
    $AnimationLayer6,
    $AnimationLayer7,
    $AnimationLayer8,
    $AnimationLayer9,
    $AnimationLayer10
]


func _process(dt: float) -> void:
    if preview_view.visible:
        var idx := _key[_preview_size-1] - 1
        preview_layers[idx].visible = not Util.glyph_blinking()
    
    if _anim_target_size > 0:
        _run_anim(dt)
    

func preview(pos: Vector2i, level: int) -> void:
    _reset_anim()
    preview_view.show()
    cursor.show()
    grid_position = pos
    _preview_size = level
    
    
func activate(level: int) -> void:
    _toggle_preview_off()
    _reset_anim()
    _anim_time_limit = ANIMATION_TIME * (level / float(Globals.WHISTLE_MAX_SIZE))
    _anim_target_size = _key[level-1]


func cancel_preview() -> void:
    _toggle_preview_off()


func get_area(level: int) -> Array[Vector2i]:
    var length := _key[level-1] * 2 - 1
    return Util.get_square_around_pos(grid_position, length, true)


func _toggle_preview_off() -> void:
    cursor.hide()
    preview_view.hide()


func _run_anim(dt: float) -> void:
    if _anim_timer >= _anim_time_limit:
        _anim_target_size = 0
        _anim_current_size = 0
        return
    
    if _anim_current_size != _anim_target_size:
        if _acc > ANIMATION_SPEED:
            _anim_current_size += 1
            _acc -= ANIMATION_SPEED
        _acc += dt

    _anim_timer += dt


func _reset_anim() -> void:
    _anim_target_size = 0
    _anim_current_size = 0
    _anim_timer = 0.0
    _acc = 0.0

