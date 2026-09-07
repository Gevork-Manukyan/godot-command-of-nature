class_name ItemAttackCardDefinition
extends ItemCardDefinition

@export var row_requirement: Array[int] = []
@export var attack_type: CardEnums.AttackType

func _init():
	item_type = CardEnums.ItemType.ATTACK
