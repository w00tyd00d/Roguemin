class_name Direction extends Object

## Abstract class containing relative vector data for each cardinal and
## diagonal direction.

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


static func get_adjacent(vec: Vector2i, from := Vector2i()) -> Array[Vector2i]:
    var i := ALL_VECTORS.find(vec)
    assert(i != -1, "Invalid direction vector given.")
    return [from + ALL_VECTORS[(i-1) % 8], from + ALL_VECTORS[(i+1) % 8]]


static func get_orthagonal(vec: Vector2i, from := Vector2i()) -> Array[Vector2i]:
    var i := ALL_VECTORS.find(vec)
    assert(i != -1, "Invalid direction vector given.")
    return [from + ALL_VECTORS[(i-2) % 8], from + ALL_VECTORS[(i+2) % 8]]

