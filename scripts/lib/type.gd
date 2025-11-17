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

## The hazards that will do harm entities.
enum Hazard { WATER, FIRE }
