class_name Enemy extends MultiTileEntity

## Base class for all enemies in-game

enum State { IDLE, CHASE, ATTACK, RETURN, DEAD }


## The current entity the enemy is targeting
var target_entity : Entity

## The current tile the enemy is about to attack
var target_tile : Tile


@onready var attack_indicator := $AttackIndicator as DualMapLayer

func _ready() -> void:
    type = Type.Entity.TREASURE

    attack_indicator.show_behind_parent = true
