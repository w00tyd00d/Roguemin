class_name PlayerCursor
extends Node2D

enum Mode { THROW, WHISTLE }

const WHISTLE_TIME := 1.5 # seconds
const WHISTLE_SPEED := 0.05 # seconds

var grid_position : Vector2i :
	set(vec):
		grid_position = vec
		position = vec * Globals.TILE_SIZE

var current_tile : Tile :
	get: 
		if not GameState.world:
			return null
		return GameState.world.get_tile(grid_position)

var mode: Mode = Mode.THROW : set = set_cursor_mode

# Whistle Preview variables
var _whistle_key : Array[int] = [2, 4, 7, 10] # layer number, not idx

var _preview_size := 1 :
	set(n):
		preview_layers[_whistle_key[_preview_size-1]-1].hide()
		_preview_size = clampi(n, Globals.WHISTLE_MIN_SIZE, Globals.WHISTLE_MAX_SIZE)

# Whistle Animation variables
var _whistle_target_size := 0
var _whistle_current_size := 0 :
	set(n):
		if _whistle_current_size != 0:
			animation_layers[_whistle_current_size-1].hide()
		_whistle_current_size = n
		if n != 0:
			animation_layers[n-1].show()

var _whistle_timer := 0.0
var _whistle_time_limit := 0.0
var _whistle_acc := 0.0

@onready var pointer := $Pointer as DualMapLayer
@onready var whistle := $Whistle as Whistle


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(dt) -> void:
	match mode:
		Mode.THROW:
			pointer.visible = not GameState.glyph_blinking()
		Mode.WHISTLE:
			if preview_view.visible:
				var idx := _whistle_key[_preview_size-1] - 1
				preview_layers[idx].visible = not GameState.glyph_blinking()
			
			if _whistle_target_size > 0:
				_run_whistle_anim(dt)

@onready var cursor := $Cursor as TileMapLayer
@onready var preview_view := $WhistlePreview as Node2D

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
	%AnimationLayer1,
	%AnimationLayer2,
	%AnimationLayer3,
	%AnimationLayer4,
	%AnimationLayer5,
	%AnimationLayer6,
	%AnimationLayer7,
	%AnimationLayer8,
	%AnimationLayer9,
	%AnimationLayer10
]


func hide_pointer() -> void:
	pointer.hide()


func set_cursor_mode(_mode: Mode) -> void:
	mode = _mode

	match mode:
		Mode.THROW:
			pointer.set_glyph(Vector2(), Glyphs.THROW_CURSOR)
		Mode.WHISTLE:
			pointer.set_glyph(Vector2(), Glyphs.WHISTLE_CURSOR)
	
	pointer.show()
	

func preview_whistle(pos: Vector2i, level: int) -> void:
	_reset_whistle_anim()
	preview_view.show()
	#cursor.show()
	grid_position = pos
	_preview_size = level
	
	
func activate_whistle(level: int) -> void:
	preview_view.hide()
	_reset_whistle_anim()
	_whistle_time_limit = WHISTLE_TIME * (level / float(Globals.WHISTLE_MAX_SIZE))
	_whistle_target_size = _whistle_key[level-1]


func cancel_whistle_preview() -> void:
	preview_view.hide()
	hide_pointer()


func get_whistle_area(level: int) -> Array[Vector2i]:
	var length := _whistle_key[level-1] * 2 - 1
	return Util.get_square_around_pos(grid_position, length, true)


func _run_whistle_anim(dt: float) -> void:
	if _whistle_timer >= _whistle_time_limit:
		_whistle_target_size = 0
		_whistle_current_size = 0
		return
	
	if _whistle_current_size != _whistle_target_size:
		if _whistle_acc > WHISTLE_SPEED:
			_whistle_current_size += 1
			_whistle_acc -= WHISTLE_SPEED
		_whistle_acc += dt

	_whistle_timer += dt


func _reset_whistle_anim() -> void:
	_whistle_target_size = 0
	_whistle_current_size = 0
	_whistle_timer = 0.0
	_whistle_acc = 0.0
