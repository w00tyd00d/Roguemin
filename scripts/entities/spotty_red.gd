class_name SpottyRed extends Enemy

## The most iconic main enemy of the franchise.


static func create() -> SpottyRed:
    return preload("res://prefabs/entities/spotty_red.tscn").instantiate()