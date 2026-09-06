class_name SageAbilities

static func get_all() -> Dictionary:
	return {
		CardNames.CEDAR: _collect_gold(),
		CardNames.GRAVEL: _collect_gold(),
		CardNames.PORELLA: _collect_gold(),
		CardNames.TORRENT: _collect_gold(),
	}

static func _collect_gold() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.COLLECT_GOLD, [], 3)],
			"Collect 3 gold."),
	]
