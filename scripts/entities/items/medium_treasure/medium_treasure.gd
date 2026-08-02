class_name MediumTreasure extends Treasure


static func create() -> MediumTreasure:
    return preload("uid://csr5a0h7f111d").instantiate()


func _ready() -> void:
    super()
    entity_name = "Medium Treasure"
