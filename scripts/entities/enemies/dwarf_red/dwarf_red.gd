class_name DwarfRed extends Enemy

## The most iconic main enemy of the franchise.

static func create() -> DwarfRed:
    return preload("uid://w5k5gfelnqws").instantiate()


func _init() -> void:
    brain = InanimateBrain.new(self)
    super()


func _ready() -> void:
    super()
    entity_name = Strings.NAME_DWARF_RED


func move_towards(target: Tile) -> bool:
    if not is_dead:
        turn_towards(target.grid_position)
    
    return super(target)