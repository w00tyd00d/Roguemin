class_name Player extends Entity

## The player object.

var unit_tether := UnitTether.new(self, 3)

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
    _draw_tether()


func add_unit(unit: Unit) -> void:
    _units[unit.type][unit] = true


func remove_unit(unit: Unit) -> void:
    _units[unit.type].erase(unit)


func _draw_tether() -> void:
    for pos in test_layer.get_used_cells():
        test_layer.set_background(pos, Glyph.NONE)
        test_layer.set_glyph(pos, Glyph.NONE)

    var tail := unit_tether.tail
    #for link in unit_tether.links:
    test_layer.set_background(tail.grid_position, Glyph.BLACK)
    test_layer.set_glyph(tail.grid_position, Glyph.TEST)
