extends Node

## Object tagging system.
##
## Used to group objects together for contextual operations with reverse lookup
## capabilities. Similar to groups for nodes, but works for any kind of object
## as long as it inherits from [Object].

# Dictionary of instance ids that holds a WeakRef object to the corresponding
# instance. Saving the WeakRef will prevent having to do a lookup operation.
# eg: _weakrefs[instance_id] = WeakRef(instance)
var _weakrefs := {}

# Dictionary of all created tags for instance grouping purposes.
# eg: _tags[tag_name] = Dictionary[instance_id]
var _tags := {}

# Dictionary of all objects with tags on them for reverse lookup purposes.
# eg: _objs[instance_id] = Dictionary[tag_name]
var _objs := {}


## Erases an object from the tag system.
func erase_obj(obj: Object) -> bool:
    var id := obj.get_instance_id()
    return _erase_by_id(id)


## Erases a tag from the tag system.
func erase_tag(tag: StringName) -> bool:
    if not _tags.has(tag):
        return false
    
    for id in _tags[tag]:
        _objs[id].erase(tag)
        if _objs[id].is_empty(): 
            _objs.erase(id)
            _weakrefs.erase(id)
    
    _tags.erase(tag)
    return true


## Cleans the tag system from any objects that no longer exist.
func clean() -> void:
    # We can't delete as we iterate, so we cache first
    var list := []
    for id in _weakrefs:
        if _weakrefs[id].get_ref() == null:
            list.append(id)
    
    for id in list:
        _erase_by_id(id)


## Adds the tag [param tag] to the object [param obj].
func add(obj: Object, tag: StringName) -> bool:
    var id := obj.get_instance_id()

    if _objs.has(id):
        if _objs[id].has(tag):
            return false
    else:
        _objs[id] = {}
        _weakrefs[id] = weakref(obj)
    
    if tag not in _tags:
        _tags[tag] = {}
    
    _objs[id][tag] = true
    _tags[tag][id] = true
    return true


## Removes the tag [param tag] from the object [param obj].
func remove(obj: Object, tag: StringName) -> bool:
    var id := obj.get_instance_id()

    if not has(obj, tag):
        return false
    
    _tags[tag].erase(id)
    _objs[id].erase(tag)
    
    if _tags[tag].is_empty():
        _tags.erase(tag)
    
    if _objs[id].is_empty(): 
        _objs.erase(id)
        _weakrefs.erase(id)

    return true


## Returns whether the object [param obj] possesses the tag [param tag].
func has(obj: Object, tag: StringName) -> bool:
    var id := obj.get_instance_id()
    return _objs.has(id) and _objs[id].has(tag)


## Returns an array of objects that all have the tag [param tag].
func get_all_with(tag: StringName) -> Array:
    if not _tags.has(tag):
        return []

    var res := []
    
    for id in _tags[tag].keys():
        var obj = _weakrefs[id].get_ref()
        if obj != null:
            res.append(_weakrefs[id].get_ref())
    
    return res


## Returns an array of tags the object [param obj] possesses.
func get_all_tags(obj: Object) -> Array:
    var id := obj.get_instance_id()
    if not _objs.has(id):
        return []
    
    return _objs[id].keys()


## Runs a callback function on every object with the tag [param tag].[br]
## The callback passes the currently iterated object as the only argument.
## [codeblock]
## func example_callback(obj: Object):
##     # Do work with obj
##
## Tag.for_each_with("test_tag", example_callback)
## [/codeblock]
## Returns the amount of callback calls that returned with a truthy value.
func for_each_with(tag: StringName, fn: Callable) -> int:
    var count := 0
    for obj in get_all_with(tag):
        if fn.call(obj):
            count += 1
    return count


func _erase_by_id(id: int) -> bool:
    if not _objs.has(id):
        return false

    for tag in _objs[id]:
        _tags[tag].erase(id)
        if _tags[tag].is_empty():
            _tags.erase(tag)
    
    _weakrefs.erase(id)
    _objs.erase(id)
    return true