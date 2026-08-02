class_name SmallTreasure extends Treasure


static func create() -> SmallTreasure:
    return preload("uid://jqye7wwbbisb").instantiate()


func _ready() -> void:
    super()
    entity_name = "Small Treasure"
