class_name Type extends Object

## Global enum container.

## The types of tiles found within the world.
enum Tile { VOID, WALL, GRASS, WATER, ENTITY, UNIT }

## The types of world chunks.
enum Chunk {
    NONE, # Chunks that are empty/untouched.
    PATH, # Chunks that consist of a path.
    ROOM, # Chunks that exist within a room.
    EXIT, # Chunks within rooms that connect to an exit.
    VOID  # Chunks that cannot be used.
}

## The types of edges connecting world chunks.
enum Edge { NONE, PATH, WALL }

## The types of units (helpers that follow the player).
enum Unit { RED, YELLOW, BLUE, NONE }

## The types of entities.
enum Entity { PLAYER, TREASURE, ENEMY }

## The elemental hazards that will do harm entities.
enum Element { PHYSICAL, WATER, FIRE }

## The types of FOV an enemy can have.
enum EnemyFov { 
    DEFAULT, ## Uses N,S,W,E for cardnial directions and 0-3 for diagonal (starting with NW going clockwise)
    COMPACT, ## Uses only 0-7 and combines corners, used for 2x2 enemies
}

## The types of attack shapes an enemy can produce.
enum Attack {
    SQUARE, ## The attack is a square around the target point.
    CIRCLE, ## The attack is a circle around the target point.
    BODY, ## The attack uses the shape of the enemy as the area.
    CONE, ## The attack fires a cone centered on the target point.
    CUSTOM, ## The attack area is custom-drawn in the editor.
}
