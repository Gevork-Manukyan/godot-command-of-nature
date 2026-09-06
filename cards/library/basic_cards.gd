class_name BasicCards

static func all() -> Array[ElementalCardDefinition]:
	return [
		timber(), bruce(), willow(),
		cobble(), flint(), rocco(),
		sprout(), herbert(), mush(),
		dribble(), dewy(), wade(),
	]

static func by_element(element: CardEnums.Element) -> Array[ElementalCardDefinition]:
	var result: Array[ElementalCardDefinition] = []
	for card in all():
		if card.element == element:
			result.append(card)
	return result

# *** Twigs ***

static func timber() -> ElementalCardDefinition:
	return _make_starter(CardNames.TIMBER, CardEnums.Element.TWIG)

static func bruce() -> ElementalCardDefinition:
	return _make_attacker(CardNames.BRUCE, CardEnums.Element.TWIG)

static func willow() -> ElementalCardDefinition:
	return _make_defender(CardNames.WILLOW, CardEnums.Element.TWIG)

# *** Pebbles ***

static func cobble() -> ElementalCardDefinition:
	return _make_starter(CardNames.COBBLE, CardEnums.Element.PEBBLE)

static func flint() -> ElementalCardDefinition:
	return _make_defender(CardNames.FLINT, CardEnums.Element.PEBBLE)

static func rocco() -> ElementalCardDefinition:
	return _make_attacker(CardNames.ROCCO, CardEnums.Element.PEBBLE)

# *** Leafs ***

static func sprout() -> ElementalCardDefinition:
	return _make_starter(CardNames.SPROUT, CardEnums.Element.LEAF)

static func herbert() -> ElementalCardDefinition:
	return _make_attacker(CardNames.HERBERT, CardEnums.Element.LEAF)

static func mush() -> ElementalCardDefinition:
	return _make_defender(CardNames.MUSH, CardEnums.Element.LEAF)

# *** Droplets ***

static func dribble() -> ElementalCardDefinition:
	return _make_starter(CardNames.DRIBBLE, CardEnums.Element.DROPLET)

static func dewy() -> ElementalCardDefinition:
	return _make_attacker(CardNames.DEWY, CardEnums.Element.DROPLET)

static func wade() -> ElementalCardDefinition:
	return _make_defender(CardNames.WADE, CardEnums.Element.DROPLET)

# Every faction's Basic Elementals are the same 3 archetypes: a starter
# (in your Sage pack), an "attacker" variant, and a "defender" variant.

static func _make_starter(name: String, element: CardEnums.Element) -> ElementalCardDefinition:
	var card := ElementalCardDefinition.new()
	card.card_name = name
	card.price = 1
	card.is_starter = true
	card.element = element
	card.attack = 2
	card.health = 2
	return card

static func _make_attacker(name: String, element: CardEnums.Element) -> ElementalCardDefinition:
	var card := ElementalCardDefinition.new()
	card.card_name = name
	card.price = 2
	card.is_starter = false
	card.element = element
	card.attack = 3
	card.health = 3
	return card

static func _make_defender(name: String, element: CardEnums.Element) -> ElementalCardDefinition:
	var card := ElementalCardDefinition.new()
	card.card_name = name
	card.price = 1
	card.is_starter = false
	card.element = element
	card.attack = 1
	card.health = 3
	return card
