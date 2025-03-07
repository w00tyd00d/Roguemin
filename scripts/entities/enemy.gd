class_name Enemy extends MultiTileEntity

## Base class for all enemies in-game

enum State { IDLE, CHASE, ATTACK, RETURN, DEAD }

## The distance at which the enemy can see units.
@export var sight_range : int

## The distance at which the enemy can attack units.
@export var attack_range : int

## The current state of the enemy.
var state := State.IDLE

## The current entity the enemy is targeting
var target_entity : Entity

## The current tile the enemy is about to attack
var target_tile : Tile

## The dictionary of units that are currently on top of the entity
var units := {}


@onready var attack_indicator := $AttackIndicator as DualMapLayer

func _ready() -> void:
    type = Type.Entity.ENEMY

    attack_indicator.show_behind_parent = true


func die() -> void:
    buck_units()
    # Change to death frame
    state = State.DEAD


func add_unit(unit: Unit) -> void:
    units[unit] = true


func remove_unit(unit: Unit) -> void:
    units.erase(unit)
    

func buck_units() -> void:
    var world := GameState.world
    var size := units.size()
    var empty_tiles := world.get_closest_empty_tiles(current_tile, size)
    var _units = units.keys()

    for i in size:
        _units[i].move_to(empty_tiles[i])
    
    units = {}
    

func queue_attack(tile: Tile) -> void:
    target_tile = tile