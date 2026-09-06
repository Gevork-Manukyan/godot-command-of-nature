class_name AbilityTarget
extends Resource

@export var scope: CardEnums.TargetScope = CardEnums.TargetScope.NONE
@export var team: CardEnums.Team = CardEnums.Team.ENEMY
@export var rows: Array[int] = []
@export var selection: CardEnums.TargetSelection = CardEnums.TargetSelection.CHOOSE_N
@export var count: int = 1
