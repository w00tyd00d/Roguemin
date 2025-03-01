extends Node

## Manages all input within the game

## Used to manage which domain is in charge of the current input
var _domain_stack : Array[Callable] = []


func _process(_dt: float) -> void:
    if _domain_stack.is_empty():
        return
    _domain_stack[-1].call()


## Add an input handler callback to the domain stack
func add(handler: Callable) -> void:
    _domain_stack.append(handler)


## Removes the most recent input handler from the domain stack
func remove() -> void:
    _domain_stack.pop_back()
