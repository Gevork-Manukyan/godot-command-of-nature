class_name AbilityEffect
extends Resource

@export var action: CardEnums.AbilityAction
@export var amount: int = 0
@export var target_team: CardEnums.Team = CardEnums.Team.ENEMY
@export var target_positions: Array[int] = []
