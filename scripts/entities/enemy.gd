class_name Enemy extends MultiTileEntity

## Base class for all enemies in-game

## The type of FOV encoding the enemy will use to assign their view positions
@export var fov_type : Type.EnemyFov

## The distance at which the enemy can see riding_units.
@export var sight_range : int

## The amount of distance the enemy is tethered to its spawn point.
@export var wander_distance : int

## The distance at which the enemy can attack riding_units.
@export var attack_range : int

## The amount of attack_damage the enemy will do to the player.
@export var attack_damage : int

## The amount of max health the enemy.
@export var maximum_health : int :
    set(n):
        maximum_health = n
        current_health = n

## The amount of health the enemy currently has.
@export var current_health : int

## The current entity the enemy is targeting
var target_entity : Entity

## The current tile the enemy is about to attack
var target_tile : Tile

## The dictionary of units that are currently on top of the entity
var riding_units := {}

## The direction the enemy is currently facing
var facing := Direction.north

## The field of view object attached to the enemy
var fov := EnemyFOV.new(self)

## The attack indicator of the enemy.
@onready var attack_indicator := $AttackIndicator as DualMapLayer


func _ready() -> void:
    super()
    type = Type.Entity.ENEMY

    attack_indicator.show_behind_parent = true


func _process(_dt: float) -> void:
    if not target_tile:
        attack_indicator.hide()
        return

    attack_indicator.visible = not GameState.glyph_blinking()


func _handle_latch_points() -> void:
    _assign_view_positions()
    super()


func get_health_percent() -> float:
    return current_health / float(maximum_health)


func turn_towards(pos: Vector2i) -> void:
    var dest_dir := Direction.by_delta(grid_position, pos)
    facing = Direction.by_turning(facing, dest_dir)


func die() -> void:
    buck_units()
    # Change to death frame
    # state = State.DEAD
    # brain.change_state(States.DEAD


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


func get_closest_target() -> Entity:
    var unit := GameState.unit_manager.get_closest_unit_to(grid_position)
    if not unit:
        var dist := Util.chebyshev_distance(player.grid_position, grid_position)
        return player if dist <= sight_range + radius else null

    var pdist := Util.chebyshev_distance(player.grid_position, grid_position)
    var udist := Util.chebyshev_distance(unit.grid_position, grid_position)

    @warning_ignore("incompatible_ternary") # This shouldn't be needed ¬_¬
    var res : Entity = player if pdist < udist else unit
    if Util.chebyshev_distance(res.grid_position, grid_position) > sight_range + radius:
        return null

    return res


func queue_attack(tile: Tile) -> void:
    target_tile =  tile
    _set_attack_position(tile.grid_position)


func attack_target() -> void:
    if not target_tile: return
    for tile in _get_attack_area(attack_indicator):
        tile.attacked(attack_damage)

    target_tile = null
    target_entity = null


func _set_attack_position(pos: Vector2i) -> void:
    var dest := pos - grid_position
    attack_indicator.grid_position = dest


func _get_attack_position() -> Vector2i:
   return attack_indicator.grid_position + grid_position


func _get_attack_area(attack_area: DualMapLayer) -> Array[Tile]:
    var res : Array[Tile] = []
    for pos in attack_area.get_used_cells():
        var apos := _get_attack_position()
        res.append(world.get_tile(pos + apos))

    return res


func _target_in_attack_range() -> bool:
    if not target_entity: return false
    var dist := grid_position.distance_to(target_entity.grid_position)
    return dist <= attack_range + radius


func _check_next_to() -> bool:
    if riding_units.size() > 1:
        return true

    for tile in get_all_latch_tiles():
        if tile.has_player or tile.has_units:
            return true

    return false


func _assign_view_positions():
    var key := fov.key

    for glyph in key:
        var cells := get_used_cells_by_id(glyph.source, glyph.atlas_pos)
        var dirs := key[glyph]
        
        for pos in cells:
            for dir: Direction in dirs:
                fov.add_view_position(dir, pos)
            
            set_glyph(pos, Glyph.LATCH_POINT)
