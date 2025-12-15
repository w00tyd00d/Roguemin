extends Node

## Assortment of utility functions.

## Returns an array of vectors from one starting vector to another
## using Bresenham's line algorithm.
func get_bresenham_line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
    var dx := absi(b.x - a.x)
    var dy := -absi(b.y - a.y)
    var sx := 1 if a.x < b.x else -1
    var sy := 1 if a.y < b.y else -1

    var err := dx + dy
    var res : Array[Vector2i] = []

    while true:
        res.append(a)
        var e2 := 2 * err
        if e2 > dy:
            if a.x == b.x: break
            err += dy
            a.x += sx
        if e2 < dx:
            if a.y == b.y: break
            err += dx
            a.y += sy

    return res


# DEPRECATE THIS!
func get_square_around_pos(
        pos: Vector2i,
        face_length: int,
        filled := false) -> Array[Vector2i]:

    if face_length < 2: return [pos]

    var half := (face_length-1) / 2.0
    var left := floori(-half)
    var right := floori(half)
    var res : Array[Vector2i] = []

    if filled:
        for y in range(left, right+1):
            for x in range(left, right+1):
                res.append(Vector2i(pos.x + x, pos.y + y))
    else:
        for n in range(left, right+1):
            res.append(Vector2i(pos.x + n, pos.y + left))
            res.append(Vector2i(pos.x + n, pos.y + right))
            if n > left and n < right:
                res.append(Vector2i(pos.x + left, pos.y + n))
                res.append(Vector2i(pos.x + right, pos.y + n))

    return res


func foreach_around_pos(
        pos: Vector2i,
        face_length: int,
        callback: Callable,
        filled := true) -> Dictionary:

    var res := {}

    if face_length < 2:
        if face_length == 0:
            return {}
        callback.call(pos, res)
        return res

    var half := (face_length-1) / 2.0
    var left := floori(-half)
    var right := floori(half)

    if filled:
        for y in range(left, right+1):
            for x in range(left, right+1):
                callback.call(Vector2i(pos.x + x, pos.y + y), res)
    else:
        for n in range(left, right+1):
            callback.call(Vector2i(pos.x + n, pos.y + left), res)
            callback.call(Vector2i(pos.x + n, pos.y + right), res)
            if n > left and n < right:
                callback.call(Vector2i(pos.x + left, pos.y + n), res)
                callback.call(Vector2i(pos.x + right, pos.y + n), res)

    return res


## Returns the Chebyshev (aka Chess) distance between two vectors.
func chebyshev(vec1: Vector2i, vec2: Vector2i) -> int:
    var dx := absi(vec1.x - vec2.x)
    var dy := absi(vec1.y - vec2.y)
    return maxi(dx, dy)


## Returns the Manhattan (aka taxicab) distance between two vectors.
func manhattan(vec1: Vector2i, vec2: Vector2i) -> int:
    var dx := absi(vec1.x - vec2.x)
    var dy := absi(vec1.y - vec2.y)
    return dx + dy
