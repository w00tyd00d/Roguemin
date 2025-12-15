extends Node

## Manages all input within the game

## Global reference to check if shift key is currently pressed
var shift_pressed := false


## Used to manage which domain is in charge of the current input
var _domain_stack : Array[Callable] = []


func _process(dt: float) -> void:
    if _domain_stack.is_empty():
        return
    _domain_stack[-1].call(dt)


## Add an input handler callback to the domain stack
func add(handler: Callable) -> void:
    _domain_stack.append(handler)


## Removes the most recent input handler from the domain stack
func remove() -> void:
    _domain_stack.pop_back()
