class_name Player extends Entity

## The player object.

@onready var camera := $Camera2D as Camera2D


static func create() -> Player:
    return preload("res://prefabs/entities/player.tscn").instantiate()


func finish_turn(_time_units: int) -> void:
    pass


func move_to(dest: Tile) -> void:
    super(dest)
    camera.align()
    