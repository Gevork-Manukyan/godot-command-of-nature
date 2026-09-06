class_name WarriorCards

static func all() -> Array[ElementalWarriorCardDefinition]:
	return [
		acorn_squire(), quill_thornback(), slumber_jack(), camou_chameleon(),
		lumber_claw(), pine_snapper(), splinter_stinger(), twine_feline(), oak_lumbertron(),
		geo_weasel(), granite_rampart(), onyx_bearer(), cackle_ripclaw(),
		redstone(), ruby_guardian(), rune_puma(), stone_defender(), terrain_tumbler(),
		botanic_fangs(), petal_mage(), thorn_fencer(), bamboo_berserker(),
		forage_thumper(), humming_herald(), iguana_guard(), moss_viper(), shrub_beetle(),
		coastal_coyote(), riptide_tiger(), river_rogue(), current_conjurer(),
		roaming_razor(), splash_basilisk(), surgesphere_monk(), typhoon_fist(), whirl_whipper(),
	]

static func by_element(element: CardEnums.Element) -> Array[ElementalWarriorCardDefinition]:
	var result: Array[ElementalWarriorCardDefinition] = []
	for card in all():
		if card.element == element:
			result.append(card)
	return result

# *** Twigs ***

static func acorn_squire() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.ACORN_SQUIRE, CardEnums.Element.TWIG, 2, 3, [1, 2], false)

static func quill_thornback() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.QUILL_THORNBACK, CardEnums.Element.TWIG, 3, 4, [1], false)

static func slumber_jack() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.SLUMBER_JACK, CardEnums.Element.TWIG, 1, 4, [2], true)

static func camou_chameleon() -> ElementalWarriorCardDefinition:
	return _make(CardNames.CAMOU_CHAMELEON, CardEnums.Element.TWIG, 7, 4, 5, [1, 2], true)

static func lumber_claw() -> ElementalWarriorCardDefinition:
	return _make(CardNames.LUMBER_CLAW, CardEnums.Element.TWIG, 4, 2, 4, [1], false)

static func pine_snapper() -> ElementalWarriorCardDefinition:
	return _make(CardNames.PINE_SNAPPER, CardEnums.Element.TWIG, 3, 1, 4, [2], false)

static func splinter_stinger() -> ElementalWarriorCardDefinition:
	return _make(CardNames.SPLINTER_STINGER, CardEnums.Element.TWIG, 5, 3, 5, [1], false)

static func twine_feline() -> ElementalWarriorCardDefinition:
	return _make(CardNames.TWINE_FELINE, CardEnums.Element.TWIG, 5, 3, 5, [2], true)

static func oak_lumbertron() -> ElementalWarriorCardDefinition:
	return _make(CardNames.OAK_LUMBERTRON, CardEnums.Element.TWIG, 9, 6, 6, [1, 2], true)

# *** Pebbles ***

static func geo_weasel() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.GEO_WEASEL, CardEnums.Element.PEBBLE, 1, 4, [1], false)

static func granite_rampart() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.GRANITE_RAMPART, CardEnums.Element.PEBBLE, 2, 3, [1, 2], true)

static func onyx_bearer() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.ONYX_BEARER, CardEnums.Element.PEBBLE, 3, 4, [2], true)

static func cackle_ripclaw() -> ElementalWarriorCardDefinition:
	return _make(CardNames.CACKLE_RIPCLAW, CardEnums.Element.PEBBLE, 4, 2, 4, [1], false)

static func redstone() -> ElementalWarriorCardDefinition:
	return _make(CardNames.REDSTONE, CardEnums.Element.PEBBLE, 4, 3, 3, [1, 2], true)

static func ruby_guardian() -> ElementalWarriorCardDefinition:
	return _make(CardNames.RUBY_GUARDIAN, CardEnums.Element.PEBBLE, 3, 2, 3, [1, 2], true)

static func rune_puma() -> ElementalWarriorCardDefinition:
	return _make(CardNames.RUNE_PUMA, CardEnums.Element.PEBBLE, 5, 3, 3, [2], false)

static func stone_defender() -> ElementalWarriorCardDefinition:
	return _make(CardNames.STONE_DEFENDER, CardEnums.Element.PEBBLE, 8, 7, 5, [1], true)

static func terrain_tumbler() -> ElementalWarriorCardDefinition:
	return _make(CardNames.TERRAIN_TUMBLER, CardEnums.Element.PEBBLE, 5, 2, 6, [2], false)

# *** Leafs ***

static func botanic_fangs() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.BOTANIC_FANGS, CardEnums.Element.LEAF, 3, 4, [1, 2], false)

static func petal_mage() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.PETAL_MAGE, CardEnums.Element.LEAF, 2, 3, [2], false)

static func thorn_fencer() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.THORN_FENCER, CardEnums.Element.LEAF, 2, 4, [1], true)

static func bamboo_berserker() -> ElementalWarriorCardDefinition:
	return _make(CardNames.BAMBOO_BERSERKER, CardEnums.Element.LEAF, 9, 6, 6, [1, 2], true)

static func forage_thumper() -> ElementalWarriorCardDefinition:
	return _make(CardNames.FORAGE_THUMPER, CardEnums.Element.LEAF, 5, 2, 5, [1], true)

static func humming_herald() -> ElementalWarriorCardDefinition:
	return _make(CardNames.HUMMING_HERALD, CardEnums.Element.LEAF, 5, 4, 3, [2], false)

static func iguana_guard() -> ElementalWarriorCardDefinition:
	return _make(CardNames.IGUANA_GUARD, CardEnums.Element.LEAF, 5, 3, 4, [2], false)

static func moss_viper() -> ElementalWarriorCardDefinition:
	return _make(CardNames.MOSS_VIPER, CardEnums.Element.LEAF, 5, 4, 2, [1, 2], false)

static func shrub_beetle() -> ElementalWarriorCardDefinition:
	return _make(CardNames.SHRUB_BEETLE, CardEnums.Element.LEAF, 3, 1, 4, [1], false)

# *** Droplets ***

static func coastal_coyote() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.COASTAL_COYOTE, CardEnums.Element.DROPLET, 3, 3, [1, 2], false)

static func riptide_tiger() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.RIPTIDE_TIGER, CardEnums.Element.DROPLET, 2, 4, [1], false)

static func river_rogue() -> ElementalWarriorCardDefinition:
	return _make_starter(CardNames.RIVER_ROGUE, CardEnums.Element.DROPLET, 2, 4, [2], true)

static func current_conjurer() -> ElementalWarriorCardDefinition:
	return _make(CardNames.CURRENT_CONJURER, CardEnums.Element.DROPLET, 3, 1, 4, [2], false)

static func roaming_razor() -> ElementalWarriorCardDefinition:
	return _make(CardNames.ROAMING_RAZOR, CardEnums.Element.DROPLET, 8, 5, 8, [1, 2], false)

static func splash_basilisk() -> ElementalWarriorCardDefinition:
	return _make(CardNames.SPLASH_BASILISK, CardEnums.Element.DROPLET, 5, 3, 5, [1], false)

static func surgesphere_monk() -> ElementalWarriorCardDefinition:
	return _make(CardNames.SURGESPHERE_MONK, CardEnums.Element.DROPLET, 3, 1, 4, [2], false)

static func typhoon_fist() -> ElementalWarriorCardDefinition:
	return _make(CardNames.TYPHOON_FIST, CardEnums.Element.DROPLET, 4, 2, 4, [1], false)

static func whirl_whipper() -> ElementalWarriorCardDefinition:
	return _make(CardNames.WHIRL_WHIPPER, CardEnums.Element.DROPLET, 4, 3, 4, [1, 2], true)

# The 3 Warriors that ship in every Sage pack ("starter") always cost 1 gold;
# the rest are market-only and priced per card.

static func _make_starter(name: String, element: CardEnums.Element, attack: int, health: int,
		row_requirement: Array[int], is_daybreak: bool) -> ElementalWarriorCardDefinition:
	var card := _make(name, element, 1, attack, health, row_requirement, is_daybreak)
	card.is_starter = true
	return card

static func _make(name: String, element: CardEnums.Element, price: int, attack: int, health: int,
		row_requirement: Array[int], is_daybreak: bool) -> ElementalWarriorCardDefinition:
	var card := ElementalWarriorCardDefinition.new()
	card.card_name = name
	card.price = price
	card.is_starter = false
	card.element = element
	card.attack = attack
	card.health = health
	card.row_requirement = row_requirement
	card.is_daybreak = is_daybreak
	return card
