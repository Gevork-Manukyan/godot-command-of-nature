class_name CardAbility
extends Resource

@export var trigger: CardEnums.AbilityTrigger
@export var condition: AbilityCondition
@export var effects: Array[AbilityEffect] = []
@export var is_optional: bool = false
## Exact wiki card text, kept as a fidelity backstop for clauses the structured
## fields above can't fully capture yet (conditional STR bonuses, per-shield
## scaling, "may" redirects, etc.).
@export_multiline var raw_text: String = ""
