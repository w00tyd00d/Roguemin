class_name States extends RefCounted

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

enum Inanimate {
    DEFAULT
}

static var inanimate_states := {
    States.Inanimate.DEFAULT: InanimateState.new()
}


enum SpottyRed {
    IDLE,

}

static var spotty_red := {
    # DEBUG, CHANGE THIS!
    States.SpottyRed.IDLE: UnitIdle.new()
}