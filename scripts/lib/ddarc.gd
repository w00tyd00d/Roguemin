class_name DDARC extends Object

#region Description
## An abstract class of the DDA raycast algorithm for 2D grids.
##
## In order to accommodate any arbitrary data structure, the raycast requires a
## callback function that will be called upon every cell traversal. This keeps
## the framework flexible while also allowing as much control as possible over
## how collision is handled. The callback function will provided a
## [DDARC.Context] object that will have all of the properties currently being
## tracked by the ray.[br][br]
##
## When the callback function returns a truthy value of any kind, the raycast
## will register that as a signal to end. If you want to return a source of 
## collision that may have caused the ray to end, you can do so using the 
## [method collider] method (see below).
##
## An example callback function may look something like this:
## [codeblock]
## func example_callback(ctx: DDARC.Context):
##     var cell := world.get_cell(ctx.grid_position)
##
##     if cell.entity:
##         return DDARC.collider(cell.entity)
##     elif cell.wall:
##         return DDARC.collider(cell.wall)
##
##     return true # returning any truthy value ends the raycast, just with no reported collision
## [/codeblock]
## This is mainly to provide the developer with any arbitrary means of collision
## to suit any particular data structure. Things like distance limiting already
## comes built into the functions used below so the [param length] argument is
## more just for debugging purposes, but it can also be helpful to have for
## other contextual reasons such as tracking damage fall off per tile, 
## explosion intensity per tile, etc.
#endregion
   

## Abstraction for setting the collider of a raycast.[br][br]Its main use is to
## be used within the callback function as a means of returning a resulting
## collider. Since the value of the collider could result in a falsy value,
## the internal logic is set up to register the first value of an array as the
## collider instead of returning the collider directly. This function, albeit
## more verbose, allows the code to be a bit more readable and inferable upon
## first glance.
## [codeblock]
## func example_callback(pos: Vector2i, cell_path: Array[Vector2i], length: float):
##     var cell := world.get_cell(pos)
##   
##     if cell.entity:
##         return [cell.entity] # Without abstraction
##     elif cell.wall:
##         return DDARC.collider(cell.wall) # With abstraction, both work
## [/codeblock]
static func collider(obj: Variant) -> Array:
    return [obj]


## Initiates a raycast from a grid position using a given [param direction]
## vector. Does support using an unaligned starting position value, but it must
## be normalized to the grid (using floats of its grid position, not its
## literal global position).
static func by_vector(
        start: Vector2,
        direction: Vector2,
        callback: Callable,
        distance := INF) -> Context:
    
    return DDARC._dda_raycast(start, direction, callback, distance)


## Initiates a raycast from one grid position to another. Does support
## unaligned position values, but position values must be normalized to the
## grid (using floats of grid positions, not literal global positions).
static func to_grid_position(
        start: Vector2,
        end: Vector2,
        callback: Callable) -> Context:
    
    var tstart := start.floor()
    var tend := end.floor()
    
    var direction := tstart.direction_to(tend)
    var distance := tstart.distance_to(tend)
    return DDARC._dda_raycast(start, direction, callback, distance)
    

static func _dda_raycast(
        start: Vector2,
        direction: Vector2,
        callback: Callable,
        distance := INF) -> Context:

    # Ensure the direction vector is normalized
    direction = direction.normalized()

    # Create new context object to be used for the callback/results
    var ctx := Context.new(start, direction)

    # We establish the slope and step size for each axis.
    var x_slope := direction.x / direction.y
    var y_slope := direction.y / direction.x
    var step_size := Vector2( sqrt(1 + y_slope * y_slope), sqrt(1 + x_slope * x_slope) )
    
    # The current grid position of the scan.
    var grid_position := Vector2i(start)
    
    # The starting offset of the ray.
    var offset := start - Vector2(grid_position)
    
    # How long the current length of each slope currently is.
    var slope_length := Vector2()
    
    # Which direction do we step to the next cell.
    var step_direction := Vector2i()
    
    # Assign the step direction and starting slope length based on the
    # direction vector and starting normalized offset within the cell.
    if direction.x < 0:
        step_direction.x = -1
        slope_length.x = offset.x * step_size.x
    else:
        step_direction.x = 1
        slope_length.x = (1 - offset.x) * step_size.x
    
    if direction.y < 0:
        step_direction.y = -1
        slope_length.y = offset.y * step_size.y
    else:
        step_direction.y = 1
        slope_length.y = (1 - offset.y) * step_size.y

    # The cached length each iteration to make sure the scan doesn't exceed
    # the given distance.
    # var current_length := 0.0

    # Store all the resulting cells hit along the path, including the original.
    var cell_path : Array[Vector2i] = [grid_position]

    while true:
        var current_length : float
        
        # Check each axis' slope length to see which is currently the
        # smallest and choose that axis as the next to walk along.
        # Cache the slope's length prior to incrementing it by its step_size
        # value to determine if we should continue the loop.
        if slope_length.x < slope_length.y:
            if (not is_equal_approx(slope_length.x, distance) and
                slope_length.x > distance):
                    break
            grid_position.x += step_direction.x
            current_length = slope_length.x
            slope_length.x += step_size.x
        else:
            if (not is_equal_approx(slope_length.y, distance) and
                slope_length.y > distance):
                    break
            grid_position.y += step_direction.y
            current_length = slope_length.y
            slope_length.y += step_size.y
        
        # Store the current cell in the cell_path array
        cell_path.append(grid_position)
        
        # We run the passed callback function to check for collisions. If it
        # returns true, it will count as a collision and the raycast will end.
        var collided = callback.call(ctx._update_path(cell_path, current_length))
        if collided:
            ctx.collider = collided[0] if typeof(collided) == TYPE_ARRAY else null
            return ctx._update_path(cell_path, current_length)
    
    return ctx._update_path(cell_path, distance)


## The container of data about a [DDARC] raycast.
class Context:
    
    ## The exact starting position of the ray in grid units.
    var start_position : Vector2
    ## The normalized direction of the ray.
    var direction : Vector2

    ## The array of grid positions the ray has visited along its path.
    var cell_path : Array[Vector2i]
    ## The length of the ray in grid units.
    var length : float
    ## The collider object the ray has intersected with, if any.
    var collider : Variant = null

    ## The grid position of the head of the ray.
    var grid_position : Vector2i :
        get: return cell_path[-1]
    
    ## The exact position of the head of the ray in grid units.
    var exact_position : Vector2 :
        get: return start_position + direction * length
    
    func _init(start: Vector2, dir: Vector2) -> void:
        start_position = start
        direction = dir
    
    func _update_path(path: Array[Vector2i], _length: float) -> Context:
        cell_path = path
        length = _length
        return self

