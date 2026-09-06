class_name ItemAttackCardDefinition
extends ItemCardDefinition

@export var row_requirement: Array[int] = []

func _init():
	item_type = CardEnums.ItemType.ATTACK
