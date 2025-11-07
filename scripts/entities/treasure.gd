class_name Treasure extends MultiTileEntity

## The main collectible the player must acquire throughout the game._acc

## The monetary money_value of the treasure.
@export var money_value : int


func _init() -> void:
    brain = InanimateBrain.new(self)
    super()


func _ready() -> void:
    type = Type.Entity.TREASURE
    super()


func collect() -> void:
    GameState.money += money_value
    super()