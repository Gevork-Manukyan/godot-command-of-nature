class_name WarriorAbilities

static func get_all() -> Dictionary:
	return {
		# Twigs
		CardNames.ACORN_SQUIRE: _acorn_squire(),
		CardNames.QUILL_THORNBACK: _quill_thornback(),
		CardNames.SLUMBER_JACK: _slumber_jack(),
		CardNames.CAMOU_CHAMELEON: _camou_chameleon(),
		CardNames.LUMBER_CLAW: _lumber_claw(),
		CardNames.PINE_SNAPPER: _pine_snapper(),
		CardNames.SPLINTER_STINGER: _splinter_stinger(),
		CardNames.TWINE_FELINE: _twine_feline(),
		CardNames.OAK_LUMBERTRON: _oak_lumbertron(),
		# Pebbles
		CardNames.GEO_WEASEL: _geo_weasel(),
		CardNames.GRANITE_RAMPART: _granite_rampart(),
		CardNames.ONYX_BEARER: _onyx_bearer(),
		CardNames.CACKLE_RIPCLAW: _cackle_ripclaw(),
		CardNames.REDSTONE: _redstone(),
		CardNames.RUBY_GUARDIAN: _ruby_guardian(),
		CardNames.RUNE_PUMA: _rune_puma(),
		CardNames.STONE_DEFENDER: _stone_defender(),
		CardNames.TERRAIN_TUMBLER: _terrain_tumbler(),
		# Leafs
		CardNames.BOTANIC_FANGS: _botanic_fangs(),
		CardNames.PETAL_MAGE: _petal_mage(),
		CardNames.THORN_FENCER: _thorn_fencer(),
		CardNames.BAMBOO_BERSERKER: _bamboo_berserker(),
		CardNames.FORAGE_THUMPER: _forage_thumper(),
		CardNames.HUMMING_HERALD: _humming_herald(),
		CardNames.IGUANA_GUARD: _iguana_guard(),
		CardNames.MOSS_VIPER: _moss_viper(),
		CardNames.SHRUB_BEETLE: _shrub_beetle(),
		# Droplets
		CardNames.COASTAL_COYOTE: _coastal_coyote(),
		CardNames.RIPTIDE_TIGER: _riptide_tiger(),
		CardNames.RIVER_ROGUE: _river_rogue(),
		CardNames.CURRENT_CONJURER: _current_conjurer(),
		CardNames.ROAMING_RAZOR: _roaming_razor(),
		CardNames.SPLASH_BASILISK: _splash_basilisk(),
		CardNames.SURGESPHERE_MONK: _surgesphere_monk(),
		CardNames.TYPHOON_FIST: _typhoon_fist(),
		CardNames.WHIRL_WHIPPER: _whirl_whipper(),
	}

# *** Twigs ***

static func _acorn_squire() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.COLLECT_GOLD, [], 0, CardEnums.AmountSource.ATTACKER_STRENGTH)],
			"When this Elemental attacks, collect gold equal to its STR."),
	]

static func _quill_thornback() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_RANGED_ATTACK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1)],
			"When another Twig Elemental in your formation ranged attacks, add 1 boost to this Elemental."),
	]

static func _slumber_jack() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])], 1)],
			"Add 1 boost to an Elemental in your Row I."),
	]

static func _camou_chameleon() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [2], 2)], 1)],
			"Choose up to 2 Elementals in your Row II and add 1 boost to each of them."),
	]

static func _lumber_claw() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_MELEE_ATTACK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [2], 2)], 1)],
			"When this Elemental melee attacks, choose up to 2 Elementals in your opponent's Row II and deal 1 DMG to each of them."),
	]

static func _pine_snapper() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_MELEE_ATTACK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])],
				0, CardEnums.AmountSource.SELF_DAMAGE_COUNT)],
			"When an Elemental in your Row I melee attacks, add 1 to its STR during the attack for each damage counter on this Elemental."),
	]

static func _splinter_stinger() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DAMAGE_DEALT,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1)],
			"After this Elemental deals DMG by attacking, add 1 boost to it."),
	]

static func _twine_feline() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_HAND,
					[AbilityBuilder.target(CardEnums.TargetScope.HAND, CardEnums.Team.SELF)]),
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
					[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.SELF)], 2),
			],
			"Discard a card from your hand, then add 2 boosts to an Elemental in your formation."),
	]

static func _oak_lumbertron() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_HAND,
					[AbilityBuilder.target(CardEnums.TargetScope.HAND, CardEnums.Team.SELF, [], 3)]),
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
					[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])],
					0, CardEnums.AmountSource.DISCARDED_COUNT),
			],
			"Discard up to 3 cards from your hand, then add 1 boost to an Elemental in your Row I for each card you discarded."),
	]

# *** Pebbles ***

static func _geo_weasel() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.COLLECT_GOLD, [], 1)],
			"When an Elemental in your formation is attacked, collect 1 gold. If that Elemental is a Pebble Elemental, collect 1 additional gold."),
	]

static func _granite_rampart() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DRAW, [], 1)],
			"Draw a card if this Elemental has at least 1 shield on it.",
			AbilityBuilder.cond(CardEnums.ConditionStat.SHIELD_COUNT, 1)),
	]

static func _onyx_bearer() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])], 1)],
			"Add 1 shield to an Elemental in your Row I."),
	]

static func _cackle_ripclaw() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_RANGED_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REDUCE_DAMAGE, [], 2)],
			"When an Elemental in your formation is ranged attacked, reduce the DMG dealt by 2."),
	]

static func _redstone() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
					[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.SELF)], 1),
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
					[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.SELF)], 1),
			],
			"Add 1 boost and 1 shield to an Elemental in your formation."),
	]

static func _ruby_guardian() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_HAND,
					[AbilityBuilder.target(CardEnums.TargetScope.HAND, CardEnums.Team.SELF, [], 2)]),
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
					[AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.SELF)],
					0, CardEnums.AmountSource.DISCARDED_COUNT, 2),
			],
			"Discard up to 2 cards from your hand, then add 2 shields to an Elemental in your formation for each card you discarded."),
	]

static func _rune_puma() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_MELEE_ATTACKED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.NEGATE_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])])],
			"When an Elemental in your Row I is melee attacked, reduce the DMG dealt to 0."),
	]

static func _stone_defender() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.COLLECT_GOLD, [], 0, CardEnums.AmountSource.SELF_SHIELD_COUNT)],
			"Collect gold equal to the number of shields on this Elemental."),
	]

static func _terrain_tumbler() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DAMAGE_ABOUT_TO_BE_DEALT_TO_ALLY,
			[AbilityBuilder.effect(CardEnums.AbilityAction.REDIRECT_DAMAGE_TO_SELF,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])])],
			"When an Elemental in your Row I would be dealt DMG, this Elemental may take that DMG instead.",
			null, true),
	]

# *** Leafs ***

static func _botanic_fangs() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.COLLECT_GOLD, [], 1)],
			"When an Elemental enters your formation, collect 1 gold. If that Elemental is a Leaf Elemental, collect 1 additional gold."),
	]

static func _petal_mage() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ENTER_ROW,
			[AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_HAND_FROM_DISCARD,
				[AbilityBuilder.target(CardEnums.TargetScope.DISCARD_PILE, CardEnums.Team.SELF)])],
			"When this Elemental enters your Row II, move a card from your discard pile to your hand."),
	]

static func _thorn_fencer() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
					[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1),
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
					[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1),
			],
			"Add 1 boost or 1 shield to this Elemental."),
	]

static func _bamboo_berserker() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_HAND_FROM_DISCARD,
				[AbilityBuilder.target(CardEnums.TargetScope.DISCARD_PILE, CardEnums.Team.SELF, [], 3)])],
			"Move up to 3 cards from your discard pile to your hand."),
	]

static func _forage_thumper() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_HAND,
					[AbilityBuilder.target(CardEnums.TargetScope.HAND, CardEnums.Team.SELF, [], 3)]),
				AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
					[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1])],
					0, CardEnums.AmountSource.DISCARDED_COUNT),
			],
			"Discard up to 3 cards from your hand, then deal DMG equal to the number of cards discarded to an Elemental in your opponent's Row I."),
	]

static func _humming_herald() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])], 1)],
			"When an Elemental enters your formation, add 1 boost to an Elemental in your Row I."),
	]

static func _iguana_guard() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1])], 1)],
			"When an Elemental enters your formation, add 1 shield to an Elemental in your Row I."),
	]

static func _moss_viper() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DEFEATED,
			[AbilityBuilder.effect(CardEnums.AbilityAction.MOVE_TO_HAND_FROM_FIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.SELF)])],
			"When this Elemental is defeated, move it to your hand instead of removing it from the game."),
	]

static func _shrub_beetle() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_LEAVE_FORMATION,
			[
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
					[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1),
				AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
					[AbilityBuilder.target(CardEnums.TargetScope.SELF)], 1),
			],
			"When an Elemental leaves your formation, add 1 boost and 1 shield to this Elemental."),
	]

# *** Droplets ***

static func _coastal_coyote() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.COLLECT_GOLD, [], 2)],
			"When another Droplet Elemental enters your Row II, collect 2 gold."),
	]

static func _riptide_tiger() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ENTER_ROW,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DRAW, [], 1)],
			"When this Elemental enters your Row I, draw a card."),
	]

static func _river_rogue() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.SWAP_FIELD_POSITION, [
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [2]),
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [3]),
			])],
			"Swap the positions of an Elemental in your Row II and an Elemental in your Row III."),
	]

static func _current_conjurer() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_BOOST,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [2])], 1)],
			"When another elemental enters your Row II, add 1 boost to that Elemental."),
	]

static func _roaming_razor() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_DAMAGE_DEALT,
			[AbilityBuilder.effect(CardEnums.AbilityAction.SWAP_FIELD_POSITION, [
				AbilityBuilder.target(CardEnums.TargetScope.SELF),
				AbilityBuilder.target(CardEnums.TargetScope.FORMATION, CardEnums.Team.SELF),
			])],
			"After this Elemental deals DMG by attacking, swap its position with a connected Elemental's."),
	]

static func _splash_basilisk() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [2])], 1)],
			"When an Elemental enters your Row II, add 1 shield to that Elemental."),
	]

static func _surgesphere_monk() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ALLY_ENTER_FORMATION,
			[AbilityBuilder.effect(CardEnums.AbilityAction.ADD_SHIELD,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [2])], 1)],
			"When another Elemental enters your Row II, add 1 shield to that Elemental."),
	]

static func _typhoon_fist() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.ON_ENTER_ROW,
			[AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE,
				[AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.ENEMY, [1])], 2)],
			"When this Elemental enters your Row I, deal 2 DMG to an Elemental in your opponent's Row I."),
	]

static func _whirl_whipper() -> Array[CardAbility]:
	return [
		AbilityBuilder.ability(
			CardEnums.AbilityTrigger.DAYBREAK,
			[AbilityBuilder.effect(CardEnums.AbilityAction.SWAP_FIELD_POSITION, [
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [1]),
				AbilityBuilder.target(CardEnums.TargetScope.ROW, CardEnums.Team.SELF, [2]),
			])],
			"Swap the positions of an Elemental in your Row I and an Elemental in your Row II."),
	]
