class_name SpottyRed extends Enemy

## The most iconic main enemy of the franchise.

const MOVE_SPEED := STEP_COST * 3
const ROTATE_SPEED := STEP_COST * 2
const ATTACK_SPEED := STEP_COST * 2


static func create() -> SpottyRed:
    return preload("uid://623fckoivhv6").instantiate()


func _init() -> void:
    brain = SpottyRedBrain.new(self)
    super()


func _ready() -> void:
    super()
    entity_name = Strings.NAME_SPOTTY_RED


func move_towards(target: Tile) -> bool:
    turn_towards(target.grid_position)
    return super(target)


func bite_attack(tile: Tile) -> Attack:
    return Attack.new(tile, func():
        var targets := Util.shuffled(attack_indicator.targeted_positions, GameState.RNG)
        var attacks := maximum_target_count
        
        for pos: Vector2i in targets:
            if world.get_tile(pos).attacked(attack_damage):
                attacks -= 1
            
            if attacks == 0:
                break
    )
