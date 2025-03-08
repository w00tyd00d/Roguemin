class_name Type extends Object

## Global enum container.

## The types of tiles found within the world.
enum Tile { VOID, WALL, GRASS, WATER, ENTITY }

## The types of edges to chunks.
enum Chunk { NONE, BORDER, PATH, EXIT, WALL, ROOM, DIAGONAL }

## The types of helper units.
enum Unit { RED, YELLOW, BLUE, NONE }

## The types of entities.
enum Entity { TREASURE, ENEMY }

## The hazards that will do harm entities.
enum Hazard { WATER, FIRE }
