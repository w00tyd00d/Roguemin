class_name Direction extends Object

## Abstract class containing relative vector data for each cardinal and
## is_diagonal direction.

const ALL_VECTORS : Array[Vector2i] = [
    Vector2i(-1,-1),
    Vector2i.UP,
    Vector2i(1,-1),
    Vector2i.RIGHT,
    Vector2i(1,1),
    Vector2i.DOWN,
    Vector2i(-1,1),
    Vector2i.LEFT,
]

static var north := Direction.new(Vector2i.UP)
static var south := Direction.new(Vector2i.DOWN)
static var west := Direction.new(Vector2i.LEFT)
static var east := Direction.new(Vector2i.RIGHT)
static var northwest := Direction.new(Vector2i(-1,-1), true)
static var northeast := Direction.new(Vector2i(1,-1), true)
static var southwest := Direction.new(Vector2i(-1,1), true)
static var southeast := Direction.new(Vector2i(1,1), true)

var vector : Vector2i
var is_diagonal : bool

var adjacent : Array[Direction] :
    get:
        if not adjacent:
            var left := ALL_VECTORS[_index-1]
            var right := ALL_VECTORS[(_index+1) % 8]
            adjacent = [Direction.by_pattern(left), Direction.by_pattern(right)]
        return adjacent

var orthagonal : Array[Direction] :
    get:
        if not orthagonal:
            var left := ALL_VECTORS[_index-2]
            var right := ALL_VECTORS[(_index+2) % 8]
            orthagonal = [Direction.by_pattern(left), Direction.by_pattern(right)]
        return orthagonal

var opposite : Direction :
    get:
        if not opposite:
            opposite = Direction.by_pattern(ALL_VECTORS[(_index-2) % 8])
        return opposite

var _index : int


static func by_pattern(pattern: Variant) -> Direction:
    match pattern:
        &"c_up", Vector2i.UP: return Direction.north
        &"c_down", Vector2i.DOWN: return Direction.south
        &"c_left", Vector2i.LEFT: return Direction.west
        &"c_right", Vector2i.RIGHT: return Direction.east
        &"c_upleft", Vector2i(-1,-1): return Direction.northwest
        &"c_upright", Vector2i(1,-1): return Direction.northeast
        &"c_downleft", Vector2i(-1,1): return Direction.southwest
        &"c_downright", Vector2i(1,1): return Direction.southeast
        _: return null


func _init(vec: Vector2i, _diagonal := false) -> void:
    vector = vec
    is_diagonal = _diagonal
    _index = ALL_VECTORS.find(vec)
    assert(_index > -1, "Invalid direction given")


func from(pos: Vector2i) -> Vector2i:
    return vector + pos