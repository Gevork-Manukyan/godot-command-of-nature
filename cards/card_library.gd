class_name CardLibrary

static func all() -> Array[CardDefinition]:
	var result: Array[CardDefinition] = []
	result.append_array(SageCards.all())
	result.append_array(ChampionCards.all())
	result.append_array(BasicCards.all())
	result.append_array(WarriorCards.all())
	result.append_array(ItemCards.all())
	_attach_abilities(result)
	return result

static func get_all() -> Dictionary:
	var result := {}
	for card in all():
		result[card.card_name] = card
	return result

static func _attach_abilities(cards: Array[CardDefinition]) -> void:
	var abilities := {}
	abilities.merge(SageAbilities.get_all())
	abilities.merge(ChampionAbilities.get_all())
	abilities.merge(WarriorAbilities.get_all())
	abilities.merge(ItemAbilities.get_all())

	for card in cards:
		if not abilities.has(card.card_name):
			continue
		if card is ElementalWarriorCardDefinition or card is ItemCardDefinition:
			card.ability = abilities[card.card_name]
