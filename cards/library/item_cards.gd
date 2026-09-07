class_name ItemCards

static func all() -> Array[ItemCardDefinition]:
	var result: Array[ItemCardDefinition] = []
	result.append_array(all_attacks())
	result.append_array(all_instants())
	result.append_array(all_utilities())
	return result

static func all_attacks() -> Array[ItemAttackCardDefinition]:
	return [
		close_strike(), far_strike(), distant_double_strike(), farsight_frenzy(),
		focused_fury(), magic_ether_strike(), natures_wrath(), primitive_strike(),
		projectile_blast(), reinforced_impact(),
	]

static func all_instants() -> Array[ItemCardDefinition]:
	return [
		droplet_charm(), leaf_charm(), pebble_charm(), twig_charm(), natural_restoration(),
		melee_shield(), natural_defense(), ranged_barrier(),
	]

static func all_utilities() -> Array[ItemCardDefinition]:
	return [elemental_incantation(), elemental_swap(), exchange_of_nature(), obliterate()]

# ------------ ATTACKS ------------

static func close_strike() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.CLOSE_STRIKE, 1, [1], true, CardEnums.AttackType.MELEE)

static func far_strike() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.FAR_STRIKE, 1, [1, 2], true, CardEnums.AttackType.RANGED)

static func distant_double_strike() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.DISTANT_DOUBLE_STRIKE, 3, [1, 2], false, CardEnums.AttackType.RANGED)

static func farsight_frenzy() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.FARSIGHT_FRENZY, 3, [1, 2, 3], false, CardEnums.AttackType.RANGED)

static func focused_fury() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.FOCUSED_FURY, 2, [1], false, CardEnums.AttackType.MELEE)

static func magic_ether_strike() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.MAGIC_ETHER_STRIKE, 5, [1], false, CardEnums.AttackType.RANGED)

static func natures_wrath() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.NATURES_WRATH, 2, [1], false, CardEnums.AttackType.MELEE)

static func primitive_strike() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.PRIMITIVE_STRIKE, 3, [1, 2], false, CardEnums.AttackType.RANGED)

static func projectile_blast() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.PROJECTILE_BLAST, 2, [1, 2], false, CardEnums.AttackType.RANGED)

static func reinforced_impact() -> ItemAttackCardDefinition:
	return _make_attack(CardNames.REINFORCED_IMPACT, 2, [1], false, CardEnums.AttackType.MELEE)

# ------------ INSTANTS ------------

static func droplet_charm() -> ItemCardDefinition:
	return _make_instant(CardNames.DROPLET_CHARM, 1, true)

static func leaf_charm() -> ItemCardDefinition:
	return _make_instant(CardNames.LEAF_CHARM, 1, true)

static func pebble_charm() -> ItemCardDefinition:
	return _make_instant(CardNames.PEBBLE_CHARM, 1, true)

static func twig_charm() -> ItemCardDefinition:
	return _make_instant(CardNames.TWIG_CHARM, 1, true)

## is_starter=false despite the wiki listing "1 in each faction deck": the
## rulebook states a Sage pack has exactly 5 Commands, which only adds up
## (2x Close Strike + 2x Far Strike + 1 faction Charm) without this card.
## Its own "Deck:" field also categorizes it as Sand & Wind Expansion-
## primary, unlike the genuinely pack-excluded Melee Shield/Natural Defense/
## Ranged Barrier, which explicitly say "Command Market". Treated as a
## regular Command-Market card instead.
static func natural_restoration() -> ItemCardDefinition:
	return _make_instant(CardNames.NATURAL_RESTORATION, 1, false)

static func melee_shield() -> ItemCardDefinition:
	return _make_instant(CardNames.MELEE_SHIELD, 3, false)

static func natural_defense() -> ItemCardDefinition:
	return _make_instant(CardNames.NATURAL_DEFENSE, 3, false)

static func ranged_barrier() -> ItemCardDefinition:
	return _make_instant(CardNames.RANGED_BARRIER, 3, false)

# ------------ UTILITIES ------------

static func elemental_incantation() -> ItemCardDefinition:
	return _make_utility(CardNames.ELEMENTAL_INCANTATION, 5)

static func elemental_swap() -> ItemCardDefinition:
	return _make_utility(CardNames.ELEMENTAL_SWAP, 2)

static func exchange_of_nature() -> ItemCardDefinition:
	return _make_utility(CardNames.EXCHANGE_OF_NATURE, 2)

static func obliterate() -> ItemCardDefinition:
	return _make_utility(CardNames.OBLITERATE, 5)

static func _make_attack(name: String, price: int, row_requirement: Array[int], is_starter: bool, attack_type: CardEnums.AttackType) -> ItemAttackCardDefinition:
	var card := ItemAttackCardDefinition.new()
	card.card_name = name
	card.price = price
	card.is_starter = is_starter
	card.row_requirement = row_requirement
	card.attack_type = attack_type
	return card

static func _make_instant(name: String, price: int, is_starter: bool) -> ItemCardDefinition:
	var card := ItemCardDefinition.new()
	card.card_name = name
	card.price = price
	card.is_starter = is_starter
	card.item_type = CardEnums.ItemType.INSTANT
	return card

static func _make_utility(name: String, price: int) -> ItemCardDefinition:
	var card := ItemCardDefinition.new()
	card.card_name = name
	card.price = price
	card.is_starter = false
	card.item_type = CardEnums.ItemType.UTILITY
	return card
