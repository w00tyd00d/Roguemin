class_name States extends Object

## An abstract class holding static references to every entity's various
## [State] objects.

## Blanket state for anything that is innately inanimate/haulable.
static var inanimate_state := InanimateState.new()

## Blanket state for anything that was once alive but is now dead.
static var dead_state := DeadState.new()


## States for innately innanimate objects. Eg: [Treasure]
static var inanimate_states := {
    States.Inanimate.DEFAULT: States.inanimate_state
}
enum Inanimate { DEFAULT }


## States for the [Unit] entity.
static var unit_states := {
    States.Unit.IDLE: UnitIdle.new(),
    States.Unit.FOLLOW: UnitFollow.new(),
    States.Unit.RETURN: UnitReturn.new(),
    States.Unit.CARRY: UnitCarry.new(),
    States.Unit.DEAD: UnitDead.new()
}
enum Unit {
    IDLE,
    FOLLOW,
    ATTACK,
    CARRY,
    RETURN,
    DEAD
}


## States for the [SpottyRed] entity.
static var spotty_red_states := {
    # DEBUG, CHANGE THIS!
    States.SpottyRed.SLEEP: SpottyRedSleep.new(),
    States.SpottyRed.CHASE: SpottyRedChase.new()
}
enum SpottyRed {
    SLEEP,
    WAKE_UP,
    CHASE,
    ATTACK,
    RETURN,
    DEAD
}

