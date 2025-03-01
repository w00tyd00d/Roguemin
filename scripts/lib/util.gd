class_name Util extends RefCounted

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


func get_square(pos: Vector2i, length: int) -> Array[Vector2i]:
    var half := (length-1) / 2.0
    var left := floori(-half)
    var right := floori(half)
    var res : Array[Vector2i] = []

    for n in range(left, right+1):
        res.append(Vector2i(pos.x + n, pos.x + left))
        res.append(Vector2i(pos.x + n, pos.x + right))
        if n > left and n < right:
            res.append(Vector2i(pos.x + left, pos.y + n))
            res.append(Vector2i(pos.x + right, pos.y + n))
    
    return res

