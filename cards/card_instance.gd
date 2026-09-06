class_name CardInstance
extends RefCounted

var definition: CardDefinition
var current_damage: int = 0
var shield_count: int = 0
var boost_count: int = 0

func _init(card_definition: CardDefinition):
	definition = card_definition

func get_effective_attack() -> int:
	if definition is ElementalCardDefinition:
		return definition.attack + boost_count
	return 0

func is_defeated() -> bool:
	if definition is ElementalCardDefinition:
		return current_damage >= definition.health
	return false
