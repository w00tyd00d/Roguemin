class_name Enemy extends MultiTileEntity

## Base class for all enemies in-game

enum State { IDLE, ATTACK, RETURN, DEAD }

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

## The current state of the unit.
var state := State.IDLE :
    set(new_state):
        var old_state = state
        state = new_state
        _on_state_exit(old_state)
        _on_state_enter(new_state)

## The current entity the enemy is targeting
var target_entity : Entity

## The current tile the enemy is about to attack
var target_tile : Tile

## The dictionary of units that are currently on top of the entity
var riding_units := {}

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


func update_time(world_time: int) -> bool:
    var old_time := time
    time = world_time

    var time_units := time - old_time
    if add_and_check_energy(time_units):
        if do_action():
            posture_points = 0
        elif state == State.ATTACK or state == State.IDLE:
            posture_points += 1
    
    return false


func get_health_percent() -> float:
    return current_health / float(maximum_health)


func die() -> void:
    buck_units()
    # Change to death frame
    state = State.DEAD


func add_unit(unit: Unit) -> void:
    riding_units[unit] = true


func remove_unit(unit: Unit) -> void:
    riding_units.erase(unit)
    

func buck_units() -> void:
    var world := GameState.world
    var size := riding_units.size()
    var empty_tiles := world.get_closest_empty_tiles(current_tile, size)
    var _units = riding_units.keys()

    for i in size:
        _units[i].move_to(empty_tiles[i])
    
    riding_units = {}


func get_closest_target() -> Entity:
    var world := GameState.world
    var player := GameState.player
    var unit := world.unit_container.get_closest_unit_to(grid_position)
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
    for tile in _get_attack_area():
        tile.attacked(attack_damage)
    
    target_tile = null
    target_entity = null
    

func return_home() -> void:
    state = State.RETURN


func do_action() -> bool:
    # var world := GameState.world

    match state:
        State.IDLE:
            if _check_next_to():
                if posture_points < 4:
                    target_entity = get_closest_target()
                    state = State.ATTACK
                    return true
                return false
            return true
        
        State.ATTACK:
            return _do_attack_action()
        
        State.RETURN:
            if posture_points < 2:
                return false
            
            var ent := get_closest_target()
            if ent:
                target_entity = ent
                state = State.ATTACK
                return true
            
            if grid_position == spawn_position:
                state = State.IDLE
                return true
                
            return move_towards(spawn_tile)

    return false


func _do_attack_action() -> bool:
    if (target_tile and posture_points < 1 or
        not target_tile and posture_points < 2):
        return false
    
    var dist := Util.chebyshev_distance(grid_position, spawn_position)
    if dist >= wander_distance:
        return_home()
        return true
    
    if target_tile:
        attack_target()
        return true
    
    if not target_entity or posture_points > 3:
        var ent := get_closest_target()
        if ent:
            target_entity = ent
        else:
            return_home()
            return true
    
    if target_entity:
        var tile := target_entity.current_tile
        if _target_in_attack_range():
            queue_attack(tile)
            return true
        
        return move_towards(tile)

    
    return false


func _set_attack_position(pos: Vector2i) -> void:
    var dest := pos - grid_position
    attack_indicator.grid_position = dest


func _get_attack_position() -> Vector2i:
   return attack_indicator.grid_position + grid_position


func _get_attack_area() -> Array[Tile]:
    var world := GameState.world
    var res : Array[Tile] = []
    for pos in attack_indicator.get_used_cells():
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


func _on_state_enter(_state: State) -> void:
    pass


func _on_state_exit(_state: State) -> void:
    match _state:
        State.ATTACK:
            target_tile = null
            target_entity = null
            posture_points = 0

