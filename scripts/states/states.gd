class_name States extends RefCounted


## Blanket state for anything that is inanimate/haulable
static var inanimate_state := InanimateState.new()
static var dead_state := DeadState.new()

enum Unit {
    IDLE,
    FOLLOW,
    ATTACK,
    CARRY,
    RETURN,
    DEAD
}

static var unit_states := {
    States.Unit.IDLE: UnitIdle.new(),
    States.Unit.FOLLOW: UnitFollow.new(),
    States.Unit.RETURN: UnitReturn.new(),
    States.Unit.CARRY: UnitCarry.new(),
    States.Unit.DEAD: UnitDead.new()
}


enum Inanimate { DEFAULT }

static var inanimate_states := {
    States.Inanimate.DEFAULT: States.inanimate_state
}


enum SpottyRed {
    SLEEP,
    CHASE,
    ATTACK,
    DEAD
}

static var spotty_red := {
    # DEBUG, CHANGE THIS!
    States.SpottyRed.SLEEP: UnitIdle.new()
}
