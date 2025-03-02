class_name Player extends Entity

## The player object.

static func create() -> Player:
    return preload("res://prefabs/entities/player.tscn").instantiate()


func finish_turn(_time_units: int) -> void:
    pass