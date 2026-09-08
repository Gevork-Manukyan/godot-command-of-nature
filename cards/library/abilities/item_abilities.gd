class_name ItemAbilities

static func get_all() -> Dictionary:
	return {
		# Attacks
		CardNames.CLOSE_STRIKE: _close_strike(),
		CardNames.FAR_STRIKE: _far_strike(),
		CardNames.DISTANT_DOUBLE_STRIKE: _distant_double_strike(),
		CardNames.FARSIGHT_FRENZY: _farsight_frenzy(),
		CardNames.FOCUSED_FURY: _focused_fury(),
		CardNames.MAGIC_ETHER_STRIKE: _magic_ether_strike(),
		CardNames.NATURES_WRATH: _natures_wrath(),
		CardNames.PRIMITIVE_STRIKE: _primitive_strike(),
		CardNames.PROJECTILE_BLAST: _projectile_blast(),
		CardNames.REINFORCED_IMPACT: _reinforced_impact(),
		# Instants
		CardNames.DROPLET_CHARM: _droplet_charm(),
		CardNames.LEAF_CHARM: _leaf_charm(),
		CardNames.PEBBLE_CHARM: _pebble_charm(),
		CardNames.TWIG_CHARM: _twig_charm(),
		CardNames.NATURAL_RESTORATION: _natural_restoration(),
		CardNames.MELEE_SHIELD: _melee_shield(),
		CardNames.NATURAL_DEFENSE: _natural_defense(),
		CardNames.RANGED_BARRIER: _ranged_barrier(),
		# Utilities
		CardNames.ELEMENTAL_INCANTATION: _elemental_incantation(),
		CardNames.ELEMENTAL_SWAP: _elemental_swap(),
		CardNames.EXCHANGE_OF_NATURE: _exchange_of_nature(),
		CardNames.OBLITERATE: _obliterate(),
	}

# ------------ ATTACKS ------------

static func _close_strike() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1])],
				0, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR to an Elemental in your opponent's Row I."),
	]

static func _far_strike() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROWS_AWAY, CardEnums.Team.ENEMY, [2])],
				0, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR to an Elemental 2 rows away in your opponent's formation."),
	]

static func _distant_double_strike() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [2], 2)],
				-2, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Choose up to 2 Elementals in your opponent's Row II and deal DMG equal to the attacking Elemental's STR -2 to each of them."),
	]

static func _farsight_frenzy() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROWS_AWAY, CardEnums.Team.ENEMY, [3])],
				-1, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR -1 to an Elemental 3 rows away in your opponent's formation."),
	]

static func _focused_fury() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1])],
				-1, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR -1 to an Elemental in your opponent's Row I. If the attacking Elemental has any number of shields on it, remove them and add 1 to its STR during the attack for each shield removed."),
	]

static func _magic_ether_strike() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.ENEMY)],
				-1, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR -1 to an Elemental in your opponent's formation."),
	]

static func _natures_wrath() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1])],
				0, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR to an Elemental in your opponent's Row I. If the attacking Elemental is a Basic Elemental, add 2 to its STR during the attack."),
	]

static func _primitive_strike() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROWS_AWAY, CardEnums.Team.ENEMY, [2])],
				0, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR to an Elemental 2 rows away in your opponent's formation. If the attacking Elemental is a Basic Elemental, add 1 to its STR during the attack."),
	]

static func _projectile_blast() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROWS_AWAY, CardEnums.Team.ENEMY, [2])],
				0, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"Deal DMG equal to the attacking Elemental's STR to an Elemental 2 rows away in your opponent's formation."),
	]

static func _reinforced_impact() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
					[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1])],
					-1, CardEnums.AmountSource.ATTACKER_STRENGTH),
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
					[AbilityBuilder.target(CardEnums.TargetScope.ATTACKING_ELEMENTAL)], 2),
			],
			"Deal DMG equal to the attacking Elemental's STR -1 to an Elemental in your opponent's Row I, then add 2 shields to the attacking Elemental."),
	]

# ------------ INSTANTS ------------

static func _droplet_charm() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DRAW, [], 1)],
			"Play this card when a Droplet Elemental in your formation is attacked. Draw a card. If that Elemental is defeated by DMG from the attack, draw an additional card."),
	]

static func _leaf_charm() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ATTACKING_ELEMENTAL)], 1)],
			"Play this card when a Leaf Elemental in your formation is attacked. Deal 1 DMG to the attacking Elemental."),
	]

static func _pebble_charm() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.SELF)], 1)],
			"Play this card when a Pebble Elemental in your formation is attacked. Add 1 shield to another Elemental in your formation."),
	]

static func _twig_charm() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.SELF)], 1)],
			"Play this card when a Twig Elemental in your formation is attacked. Add 1 boost to another Elemental in your formation."),
	]

static func _natural_restoration() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REDUCE_DAMAGE, [], 1)],
			"Play this card when an Elemental in your formation is attacked. Reduce the DMG dealt by 1."),
	]

static func _melee_shield() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_MELEE_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REDUCE_DAMAGE, [], 2)],
			"Play this card when an Elemental in your formation is melee attacked. Reduce the DMG dealt by 2."),
	]

static func _natural_defense() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REDUCE_DAMAGE, [], 1)],
			"Play this card when an Elemental in your formation is attacked. Reduce the DMG dealt by 1."),
	]

static func _ranged_barrier() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_RANGED_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REDUCE_DAMAGE, [], 2)],
			"Play this card when an Elemental in your formation is ranged attacked. Reduce the DMG dealt by 2."),
	]

# ------------ UTILITIES ------------

static func _elemental_incantation() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_HAND,
					[AbilityBuilder.target(CardEnums.TargetScope.HAND, CardEnums.Team.SELF, [], 3)]),
				AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
					[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.ENEMY, [], 6)], 1),
			],
			"Discard 3 cards from your hand. Choose up to 6 Elementals in your opponent's formation and deal 1 DMG to each of them."),
	]

static func _elemental_swap() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.SWAP_FIELD_POSITION, [
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1]),
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [2]),
			])],
			"Swap the positions of an Elemental in your opponent's Row I and an Elemental in their Row II."),
	]

static func _exchange_of_nature() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.SWAP_FIELD_POSITION, [
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1]),
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [3]),
			])],
			"Swap the positions of an Elemental in your Row I and an Elemental in your Row III."),
	]

static func _obliterate() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_PLAY,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.REMOVE_ALL_BOOSTS_AND_SHIELDS,
					[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.ENEMY)]),
				AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
					[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.ENEMY)], 2),
			],
			"Remove all boosts and shields from an Elemental in your opponent's formation, then deal 2 DMG to that Elemental."),
	]
