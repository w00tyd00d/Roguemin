class_name Player extends Entity

## The player object.

var unit_tether := UnitTether.new(self, 3)

var unit_toggle := {
    Type.Unit.RED: true,
    Type.Unit.YELLOW: true,
    Type.Unit.BLUE: true,
}

var selected_unit := Type.Unit.NONE :
    set(type):
        selected_unit = type
        GameState.update_selected_unit.emit(type)

## The number of units within the player's squad
var unit_count := 0 :
    set(n):
        unit_count = n
        GameState.update_squad_count.emit(unit_count)
        GameState.update_selected_unit.emit(selected_unit)

# var whistle_size : int :
#     set(size):
#         size = clampi(size, 1, 5)

# var swarm_size : int :
#     set(size):
#         size = clampi(size, 1, 5)


var _units := {
    Type.Unit.RED: {},
    Type.Unit.YELLOW: {},
    Type.Unit.BLUE: {},
}

@onready var camera := $Camera2D as Camera2D


@onready var test_layer : DualMapLayer


static func create() -> Player:
    return preload("res://prefabs/entities/player.tscn").instantiate()


func _ready() -> void:
    unit_tether.reset()


func finish_turn(_time_units: int) -> void:
    pass


func move_to(dest: Tile) -> void:
    super(dest)
    camera.align()
    unit_tether.update()

    # DEBUG
    # _draw_tether()


func cycle_selected_unit(left := false) -> void:
    var strikes := 0
    var type := selected_unit
    while strikes < 3:

        if left: type = (4 + type - 1) % 4
        else: type = (type + 1) % 4

        if type == Type.Unit.NONE: continue
        if get_unit_count(type) > 0:
            selected_unit = type
            return

        strikes += 1
        
    selected_unit = Type.Unit.NONE

func add_unit(unit: Unit) -> void:
    if _units[unit.type].has(unit): return
    
    _units[unit.type][unit] = true
    unit_count += 1

    if selected_unit == Type.Unit.NONE:
        selected_unit = unit.type
        

func remove_unit(unit: Unit) -> void:
    if not _units[unit.type].has(unit): return 
    
    _units[unit.type].erase(unit)
    unit_count -= 1

    if unit_count == 0:
        selected_unit = Type.Unit.NONE


func toggle_unit(type: Type.Unit) -> void:
    if type == Type.Unit.NONE: return
    unit_toggle[type] = not unit_toggle[type]
    GameState.update_unit_toggle.emit(unit_toggle)


func get_unit_count(type := Type.Unit.NONE) -> int:
    if type == Type.Unit.NONE:
        return 0
    return _units[type].size()    


func grab_unit(type: Type.Unit) -> Unit:
    if get_unit_count(type) == 0:
        return null
    return _units[type].keys()[0]


func throw_unit(unit: Unit, tile: Tile) -> void:
    if not unit: return
    unit.throw_to(tile)
    remove_unit(unit)


func get_all_units() -> Array[Unit]:
    var res : Array[Unit] = []
    for dict in _units.values():
        res.append_array((dict.keys()))
    return res


func _draw_tether() -> void:
    for pos in test_layer.get_used_cells():
        test_layer.set_background(pos, Glyph.NONE)
        test_layer.set_glyph(pos, Glyph.NONE)

    var tail := unit_tether.tail
    test_layer.set_background(tail.grid_position, Glyph.BLACK)
    test_layer.set_glyph(tail.grid_position, Glyph.TEST)
