class_name UnitTether extends RefCounted

## An invisible unit guide.
##
## Acts as an invisible "ball-and-chain" object that follows the player
## around to track where units should rally to when they're following.

var player : Player
var links : Array[Link] = []

var tail : Link :
    get: return links[-1] if not links.is_empty() else null


func _init(_player: Player, count: int) -> void:
    player = _player
    
    for n in count+1:
        var link := Link.new()
        if not links.is_empty():
            links[-1].next_link = link
        links.append(link)


func get_link(idx: int) -> Link:
    return links[idx]


func reset() -> void:
    for link in links:
        link.grid_position = player.grid_position


func update() -> void:
    links[0].update(player.grid_position)


## A node within the [UnitTether] object.
class Link:
    var grid_position : Vector2i
    var next_link : Link

    var current_tile : Tile :
        get: return GameState.world.get_tile(grid_position)

    func update(pos: Vector2i):
        if next_link and pos.distance_to(next_link.grid_position) >= 2:
            next_link.update(grid_position)
        grid_position = pos