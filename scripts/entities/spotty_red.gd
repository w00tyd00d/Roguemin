class_name SpottyRed extends Enemy

## The most iconic main enemy of the franchise.

static func create() -> SpottyRed:
    return preload("uid://623fckoivhv6").instantiate()


func _init() -> void:
    brain = SpottyRedBrain.new(self)
    super()


func _ready() -> void:
    super()
    entity_name = Strings.NAME_SPOTTY_RED
