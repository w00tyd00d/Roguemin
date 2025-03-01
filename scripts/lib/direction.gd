class_name Direction extends Object

## Abstract class containing relative vector data for each cardinal and
## diagonal direction.

const ALL_VECTORS : Array[Vector2] = [
    Vector2(-1,-1),
    Vector2.UP,
    Vector2(1,-1),
    Vector2.RIGHT,
    Vector2(1,1),
    Vector2.DOWN,
    Vector2(-1,1),
    Vector2.LEFT,
]


static func get_adjacent(vec: Vector2, from := Vector2()) -> Array[Vector2]:
    var i := ALL_VECTORS.find(vec)
    assert(i != -1, "Invalid direction vector given.")
    return [from + ALL_VECTORS[(i-1) % 8], from + ALL_VECTORS[(i+1) % 8]]


static func get_orthagonal(vec: Vector2, from := Vector2()) -> Array[Vector2]:
    var i := ALL_VECTORS.find(vec)
    assert(i != -1, "Invalid direction vector given.")
    return [from + ALL_VECTORS[(i-2) % 8], from + ALL_VECTORS[(i+2) % 8]]

