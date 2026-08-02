class_name Rooms extends Object


static var TEST := preload("uid://mwsjhul1qwks").instantiate()

static var HOME_BASE := preload("uid://n77rw20oy6ru").instantiate()

static var ROOM_2X2: RoomBlueprint = preload("uid://bj4uvic1ud8po").instantiate()
static var ROOM_2X3: RoomBlueprint = preload("uid://d33l7t766au5j").instantiate()
static var ROOM_2X4: RoomBlueprint = preload("uid://bt5e55sf3e6cc").instantiate()
static var ROOM_3X2: RoomBlueprint = preload("uid://dm7daebuk2shh").instantiate()
static var ROOM_3X3: RoomBlueprint = preload("uid://dgkdc43u0h6s2").instantiate()
static var ROOM_3X4: RoomBlueprint = preload("uid://bncy22p7brocd").instantiate()
static var ROOM_4X2: RoomBlueprint = preload("uid://75gp6mlj3l34").instantiate()
static var ROOM_4X3: RoomBlueprint = preload("uid://bbrle4xbg7b6c").instantiate()

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

static func pick_random() -> RoomBlueprint:
    return ALL_ROOMS.pick_random()