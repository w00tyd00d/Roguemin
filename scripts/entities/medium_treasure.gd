class_name MediumTreasure extends Treasure


static func create() -> MediumTreasure:
    return preload("res://prefabs/entities/medium_treasure.tscn").instantiate()


func _ready() -> void:
    super()
    entity_name = "Medium Treasure"
