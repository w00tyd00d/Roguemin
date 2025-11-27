@tool

class_name AttackIndicator extends DualMapLayer

## The attack shape of this indicator.
@export var attack_type : Type.Attack

## The distance of how big the attack area will be from the origin of the attack
@export_range(0,10,1) var attack_range : float