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
    var half_count := latch_point_count / 2.0
    
    if carrier_count >= half_count:
        var val := (carrier_count - half_count) / (latch_point_count * Globals.ENERGY_CAP)
        carry_energy += val * time_units
    else:
        carry_energy = 0.0

    return can_act


func do_action() -> bool:
    var pos := get_next_flow_field_position()
    var dest := GameState.world.get_tile(pos)
    
    carry_energy -= 1.0
    move_to(dest)
    _check_for_collection()    
    return true


func collect() -> void:
    GameState.money += money_value
    super()
