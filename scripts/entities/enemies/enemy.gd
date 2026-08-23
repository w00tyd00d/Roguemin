class_name Enemy extends MultiTileEntity

## Base class for all enemies in-game

## The signal fired when the enemy's health changed
signal health_changed

## The signal fired when the enemy rotates their FOV
signal facing_changed

## The type of FOV encoding the enemy will use to assign their view positions
@export var fov_type : Type.EnemyFov

## The distance at which the enemy can see targets.
@export var sight_range : int

## The amount of distance the enemy is tethered to its spawn point.
@export var wander_distance : int

## The distance at which the enemy can attack targets.
@export var attack_range : int

## The amount of attack damage the enemy will do to the player.
@export var attack_damage : int

## The maximum number of targets the enemy can attack in a single attack.
## If set to [code]0[/code], will target the entirety of the area.
@export var maximum_target_count := 0 :
    get: return 999 if maximum_target_count <= 0 else maximum_target_count

## The amount of max health the enemy.
@export var maximum_health : int :
    set(n):
        maximum_health = n
        current_health = n

## The amount of health the enemy currently has.
var current_health : int :
    set(n):
        current_health = n
        health_changed.emit()

## The current entity the enemy is targeting.
var target_entity : Entity

## The queued attack command if the entity has prepared an attack.
## See [method prepare_attack].
var queued_attack : Attack

## The dictionary of units that are currently on top of the entity.
var riding_units := {}

## The direction the enemy is currently facing.
var facing : Direction : 
    set(dir):
        facing = dir
        _update_eye_position()
        facing_changed.emit()


## The current cached grid position of the enemy's eyes.
var eye_position : Vector2i 

## The field of view object attached to the enemy.
var fov := EnemyFOV.new(self)

## Whether or not the enemy is currently dead.
var is_dead: bool:
    get: return brain.state == brain.dead_state

## The attack indicator of the enemy.
@onready var attack_indicator := $AttackIndicator as AttackIndicator

## Proxy to the [member AttackIndicator.attack_type] property.
@onready var attack_type: Type.Attack:
    get: return attack_indicator.attack_type

## Proxy to the [member AttackIndicator.area_size] property.
@onready var attack_size: int:
    get: return int(attack_indicator.area_size)

## The [QuickInfo] object attached to the enemy.
@onready var quick_info := $QuickInfo as QuickInfo


func _ready() -> void:
    super()
    type = Type.Entity.ENEMY
    facing = Direction.northwest

    attack_indicator.entity = self
    quick_info.grid_position = grid_position


func _handle_latch_points() -> void:
    _assign_view_positions()
    super()


func get_health_percent() -> float:
    return current_health / float(maximum_health)


func get_health_percent_num() -> int:
    return floori(get_health_percent() * 100)


func take_damage(dmg: int) -> void:
    current_health -= maxi(0, dmg)
    if current_health <= 0:
        current_health = 0
        die()


func turn_towards(pos: Vector2i) -> bool:
    var dest_dir := Direction.by_delta(grid_position, pos)
    
    if dest_dir == facing:
        return false
    
    facing = Direction.by_turning(facing, dest_dir)
    return true


func die() -> void:
    buck_units()
    brain.die()


func add_unit(unit: Unit) -> void:
    riding_units[unit] = true


func remove_unit(unit: Unit) -> void:
    riding_units.erase(unit)


func buck_units() -> void:
    var size := riding_units.size()
    var empty_tiles := world.get_closest_empty_tiles(current_tile, size)

    for unit: Unit in riding_units:
        unit.move_to(empty_tiles.pop_back())

    riding_units = {}


func get_closest_unit(radial := false) -> Unit:
    return GameState.unit_manager.get_closest_unit_to(eye_position, radial, radius)


func get_closest_target(radial := false) -> Entity:
    # Since we check the squared distance if radial, the limit distance must
    # also be squared
    var limit := sight_range * sight_range if radial else sight_range
    var pdist := World.distance(player.grid_position, eye_position, radial, true)
    var unit := get_closest_unit(radial)

    if not unit:
        return player if pdist <= limit else null

    var udist := World.distance(unit.grid_position, eye_position, radial, true)

    if pdist < udist and pdist <= limit:
        return player
    
    if udist <= limit:
        return unit

    return null


func can_attack(pos: Vector2i, radial := false) -> bool:
    var limit := attack_range * attack_range if radial else attack_range
    for dpos: Vector2i in fov.get_view_positions(facing):
        var vpos := grid_position + dpos
        if World.distance(vpos, pos, radial, true) <= limit:
            return true
    return false


func prepare_attack(attack: Attack) -> void:
    queued_attack = attack
    attack_indicator.prepare_attack(attack)


func attack_target() -> void:
    assert(queued_attack)

    queued_attack.run()

    attack_indicator.deactivate()
    queued_attack = null
    target_entity = null


func center_from_facing() -> Vector2i:
    return center_from_pos(grid_position + facing.vector)


func _set_grid_position(pos: Vector2i) -> void:
    var has_init := position != Vector2()
    
    super(pos)
    
    if has_init:
        _update_eye_position()
    
    if quick_info:
        quick_info.grid_position = pos
    

func _update_eye_position() -> void:
    # NOTE: At the moment, we assume all enemies are circular   
    eye_position = center_from_facing() + Vector2i(facing.normalized * radius)


func _assign_view_positions():
    for glyph in fov.key:
        var cells := get_used_cells_by_id(glyph.source, glyph.atlas_pos)
        var dirs := fov.key[glyph]
        
        for pos in cells:
            for dir: Direction in dirs:
                fov.add_view_position(dir, pos)
            
            set_glyph(pos, Glyphs.LATCH_POINT)


## A command pattern object that handles the details of an attack.
class Attack:
    var tile : Tile
    var action : Callable
    var angle: float
    var size: int
    var type: Type.Attack

    func _init(
        _tile: Tile,
        _action: Callable,
        _angle := 0.0,
        _size := -1,
        _type := Type.Attack.DEFAULT) -> void:
        
        tile = _tile
        action = _action
        angle = _angle
        size = _size
        type = _type
        
    func run() -> void:
        action.call()
