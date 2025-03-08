class_name Rooms extends Object


static var TEST := preload("res://prefabs/rooms/test_room.tscn").instantiate()

static var HOME_BASE := preload("res://prefabs/rooms/main_base_room.tscn").instantiate()

static var ROOM_2X2 := preload("res://prefabs/rooms/room_2x2.tscn").instantiate()
static var ROOM_2X3 := preload("res://prefabs/rooms/room_2x3.tscn").instantiate()
static var ROOM_2X4 := preload("res://prefabs/rooms/room_2x4.tscn").instantiate()
static var ROOM_3X2 := preload("res://prefabs/rooms/room_3x2.tscn").instantiate()
static var ROOM_3X3 := preload("res://prefabs/rooms/room_3x3.tscn").instantiate()
static var ROOM_3X4 := preload("res://prefabs/rooms/room_3x4.tscn").instantiate()
static var ROOM_4X2 := preload("res://prefabs/rooms/room_4x2.tscn").instantiate()
static var ROOM_4X3 := preload("res://prefabs/rooms/room_4x3.tscn").instantiate()

static var ALL_ROOMS : Array[RoomBlueprint] = [
    ROOM_2X2,
    ROOM_2X3,
    ROOM_2X4,
    ROOM_3X2,
    ROOM_3X3,
    ROOM_3X4,
    ROOM_4X2,
    ROOM_4X3
]