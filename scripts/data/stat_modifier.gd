class_name StatModifier
extends Resource
## One stat change applied by an upgrade or passive. See StatBlock for how modes combine.

enum Mode { FLAT, PERCENT, MULT }

@export var stat: StringName
@export var mode: Mode = Mode.PERCENT
@export var amount: float = 0.0
