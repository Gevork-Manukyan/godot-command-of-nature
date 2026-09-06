class_name SageCards

static func all() -> Array[ElementalSageCardDefinition]:
	return [cedar(), gravel(), porella(), torrent()]

static func by_element(element: CardEnums.Element) -> Array[ElementalSageCardDefinition]:
	var result: Array[ElementalSageCardDefinition] = []
	for card in all():
		if card.element == element:
			result.append(card)
	return result

static func cedar() -> ElementalSageCardDefinition:
	return _make(CardNames.CEDAR, CardEnums.Element.TWIG, CardEnums.Sage.CEDAR)

static func gravel() -> ElementalSageCardDefinition:
	return _make(CardNames.GRAVEL, CardEnums.Element.PEBBLE, CardEnums.Sage.GRAVEL)

static func porella() -> ElementalSageCardDefinition:
	return _make(CardNames.PORELLA, CardEnums.Element.LEAF, CardEnums.Sage.PORELLA)

static func torrent() -> ElementalSageCardDefinition:
	return _make(CardNames.TORRENT, CardEnums.Element.DROPLET, CardEnums.Sage.TORRENT)

static func _make(name: String, element: CardEnums.Element, sage: CardEnums.Sage) -> ElementalSageCardDefinition:
	var card := ElementalSageCardDefinition.new()
	card.card_name = name
	card.price = 1
	card.is_starter = true
	card.element = element
	card.attack = 3
	card.health = 12
	card.row_requirement = [1, 2, 3]
	card.is_daybreak = true
	card.sage = sage
	return card
