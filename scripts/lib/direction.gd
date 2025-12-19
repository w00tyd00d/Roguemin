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

# Change how you want your RNG to be accessed
static var RNG : RandomNumberGenerator : 
    get: return GameState.RNG

static var none := Direction.new(Vector2i())

static var north := Direction.new(Vector2i.UP)
static var south := Direction.new(Vector2i.DOWN)
static var west := Direction.new(Vector2i.LEFT)
static var east := Direction.new(Vector2i.RIGHT)
static var northwest := Direction.new(Vector2i(-1,-1))
static var northeast := Direction.new(Vector2i(1,-1))
static var southwest := Direction.new(Vector2i(-1,1))
static var southeast := Direction.new(Vector2i(1,1))

var vector : Vector2i
var normalized : Vector2

var is_diagonal : bool
var is_vertical : bool
var is_horizontal : bool

var adjacent : Array[Direction] :
    get:
        if vector == Vector2i(): return [Direction.none, Direction.none]
        if not adjacent:
            var left := ALL_VECTORS[(_index-1 + 8) % 8]
            var right := ALL_VECTORS[(_index+1) % 8]
            adjacent = [Direction.by_pattern(left), Direction.by_pattern(right)]
        return adjacent

var orthogonal : Array[Direction] :
    get:
        if vector == Vector2i(): return [Direction.none, Direction.none]
        if not orthogonal:
            var left := ALL_VECTORS[(_index-2 + 8) % 8]
            var right := ALL_VECTORS[(_index+2) % 8]
            orthogonal = [Direction.by_pattern(left), Direction.by_pattern(right)]
        return orthogonal


var oppadjacent : Array[Direction] :
    get:
        if vector == Vector2i(): return [Direction.none, Direction.none]
        if not adjacent:
            var left := ALL_VECTORS[(_index-3 + 8) % 8]
            var right := ALL_VECTORS[(_index+3) % 8]
            adjacent = [Direction.by_pattern(left), Direction.by_pattern(right)]
        return adjacent


var opposite : Direction :
    get:
        if vector == Vector2i(): return Direction.none
        if not opposite:
            opposite = Direction.by_pattern(ALL_VECTORS[(_index+4) % 8])
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


static func by_normalized(nvec: Vector2) -> Direction:
    # Ensure the passed vector is in fact normalized
    nvec = nvec.normalized()

    if nvec.is_zero_approx():
        return Direction.none

    var best_dot := -1.0
    var best_vec : Vector2i

    for vec in ALL_VECTORS:
        var dot := nvec.dot(Vector2(vec).normalized())
        if dot > best_dot:
            best_dot = dot
            best_vec = vec

    return Direction.by_pattern(best_vec)


static func by_delta(from_pos: Vector2i, to_pos: Vector2i) -> Direction:
    if from_pos == to_pos:
        return Direction.none
    return Direction.by_normalized(Vector2(from_pos).direction_to(to_pos))


static func by_turning(from_dir: Direction, to_dir: Direction) -> Direction:
    if from_dir == to_dir: return from_dir
    
    var size := ALL_VECTORS.size()
    var fidx := from_dir._index
    var tidx := to_dir._index
    
    var rdest := tidx + size if fidx > tidx else tidx
    var lstart := fidx + size if fidx < tidx else fidx
    
    var right := rdest - fidx
    var left := lstart - tidx

    var rot: int

    if right < left: 
        rot = 1  # turn right
    elif left < right:
        rot = 0  # turn left
    else:
        rot = Direction.RNG.randi_range(0,1)
    
    return from_dir.adjacent[rot]


static func get_all(shuffled := false) -> Array[Direction]:
    var res : Array[Direction] = [
        north,
        south,
        west,
        east,
        northwest,
        northeast,
        southwest,
        southeast,
    ]

    if shuffled: res.shuffle()
    return res


static func get_cardinal(shuffled := false) -> Array[Direction]:
    var res : Array[Direction] = [
        north,
        south,
        west,
        east
    ]

    if shuffled: res.shuffle()
    return res


func _init(vec: Vector2i, _diagonal := false) -> void:
    vector = vec
    normalized = Vector2(vec).normalized()

    if vec == Vector2i():
        _index = -1
        return

    is_diagonal = absi(vector.x) + absi(vector.y) == 2
    is_vertical = vector.x == 0
    is_horizontal = vector.y == 0

    _index = ALL_VECTORS.find(vec)
    assert(_index > -1, "Invalid direction given")
