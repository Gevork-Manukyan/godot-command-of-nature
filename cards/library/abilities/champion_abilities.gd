class_name ChampionAbilities

static func get_all() -> Dictionary:
	return {
		CardNames.VIX_VANGUARD: _vix_vanguard(),
		CardNames.HORNED_HOLLOW: _horned_hollow(),
		CardNames.CALAMITY_LEOPARD: _calamity_leopard(),
		CardNames.JADE_TITAN: _jade_titan(),
		CardNames.BOULDERHIDE_BRUTE: _boulderhide_brute(),
		CardNames.OXEN_AVENGER: _oxen_avenger(),
		CardNames.AGILE_ASSAILANT: _agile_assailant(),
		CardNames.BOG_BLIGHT: _bog_blight(),
		CardNames.KOMODO_KIN: _komodo_kin(),
		CardNames.TIDE_TURNER: _tide_turner(),
		CardNames.KING_CRUSTACEAN: _king_crustacean(),
		CardNames.FROSTFALL_EMPEROR: _frostfall_emperor(),
	}

static func _vix_vanguard() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DRAW, [], 1)],
			"Draw a card if this Elemental has at least 1 boost on it.",
			AbilityBuilder.cond(CardEnums.ConditionStat.BOOST_COUNT, 1)),
	]

static func _horned_hollow() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DEFEAT_ENEMY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REMOVE_ALL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)])],
			"When this Elemental defeats an Elemental in your opponent's formation, remove all damage counters from this Elemental."),
	]

static func _calamity_leopard() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DONT_REMOVE_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)])],
			"When this Elemental attacks, do not remove boosts from it."),
	]

static func _jade_titan() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DAMAGE_DEALT,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF_SAGE)], 1)],
			"When this Elemental deals DMG by attacking, add 1 shield to your Sage."),
	]

static func _boulderhide_brute() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_SHIELD_ADDED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1)],
			"When you add any number of shields to this Elemental, add 1 boost to it."),
	]

static func _oxen_avenger() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_SHIELD_REMOVED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.ENEMY)], 1)],
			"When an Elemental in your formation has any number of shields removed from it, deal 1 DMG to an Elemental in your opponent's formation."),
	]

static func _agile_assailant() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1)],
			"When an Elemental enters your formation, add 1 boost to this Elemental."),
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_LEAVE_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1)],
			"When an Elemental leaves your formation, add 1 shield to this Elemental."),
	]

static func _bog_blight() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_FIELD,
					[AbilityBuilder.target(CardEnums.TargetScope.SELF)]),
				AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
					[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1, 2])], 3),
			],
			"Move this Elemental to your discard pile, then deal 3 DMG to an Elemental in your opponent's Row I or Row II."),
	]

static func _komodo_kin() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DEFEAT_ENEMY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_FIELD_FROM_DISCARD,
				[AbilityBuilder.target(CardEnums.TargetScope.DISCARD_PILE, CardEnums.Team.SELF)])],
			"When this Elemental defeats an Elemental in your opponent's formation, move an Elemental from your discard pile to your formation."),
	]

static func _tide_turner() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DRAW, [], 1)],
			"When this Elemental is attacked, draw a card."),
	]

static func _king_crustacean() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DAMAGE_ABOUT_TO_BE_DEALT_TO_ALLY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REDIRECT_DAMAGE_TO_SELF,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)])],
			"When a connected Elemental would be dealt DMG, you may swap it's position with this Elemental's; this Elemental takes that DMG instead.",
			null, true),
	]

static func _frostfall_emperor() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ENTER_ROW,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [3])], 2)],
			"When this Elemental enters your Row I, deal 2 DMG to an Elemental in your opponent's Row III."),
	]
