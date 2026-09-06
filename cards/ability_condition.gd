class_name AbilityCondition
extends Resource

@export var subject: CardEnums.Team = CardEnums.Team.SELF
@export var stat: CardEnums.ConditionStat
@export var comparator: CardEnums.Comparator = CardEnums.Comparator.GREATER_OR_EQUAL
@export var amount: int
