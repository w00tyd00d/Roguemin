class_name LargeTreasure extends Treasure


static func create() -> LargeTreasure:
	return preload("uid://bg13ui55262v").instantiate()


func _ready() -> void:
	super()
	entity_name = "Large Treasure"
