class_name Treasure extends MultiTileEntity

## The main collectible the player must acquire throughout the game._acc

## The monetary money_value of the treasure.
@export var money_value : int

## The granular energy money_value that builds up dynamically based on the amount
## of carriers latched on to the entity.

func _ready() -> void:
    type = Type.Entity.TREASURE
    super()


func add_and_check_energy(time_units: int) -> bool:
    @warning_ignore("integer_division")
    var half_count := latch_point_count / 2

    if carrier_count < half_count:
        action_energy = 0
        return false

    var diff : float = carrier_count - half_count
    var val := diff / latch_point_count

    action_energy += int(val * time_units)

    if can_act: do_action()

    return can_act


func do_action() -> bool:
    get_hauled()
    return true


func collect() -> void:
    GameState.money += money_value
    super()


func _get_can_act() -> bool:
    # TAKE INTO ACCOUNT UNITS WITH SPICY SPRAY
    # AND IF PLAYER HAS RUSH BOOTS
    return action_energy >= Globals.DEFAULT_ENERGY_STEP
