class_name LargeTreasure extends Treasure


static func create() -> LargeTreasure:
    return preload("res://prefabs/entities/large_treasure.tscn").instantiate()


func _ready() -> void:
    super()
    entity_name = "Large Treasure"
