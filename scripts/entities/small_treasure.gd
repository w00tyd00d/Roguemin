class_name SmallTreasure extends Treasure


static func create() -> SmallTreasure:
    return preload("res://prefabs/entities/small_treasure.tscn").instantiate()


func _ready() -> void:
    super()
    entity_name = "Small Treasure"