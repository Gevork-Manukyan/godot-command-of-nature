class_name ChampionCards

static func all() -> Array[ElementalChampionCardDefinition]:
	return [
		vix_vanguard(), horned_hollow(), calamity_leopard(),
		jade_titan(), boulderhide_brute(), oxen_avenger(),
		agile_assailant(), bog_blight(), komodo_kin(),
		tide_turner(), king_crustacean(), frostfall_emperor(),
	]

static func by_element(element: CardEnums.Element) -> Array[ElementalChampionCardDefinition]:
	var result: Array[ElementalChampionCardDefinition] = []
	for card in all():
		if card.element == element:
			result.append(card)
	return result

# *** Twigs ***

static func vix_vanguard() -> ElementalChampionCardDefinition:
	return _make(CardNames.VIX_VANGUARD, CardEnums.Element.TWIG, 3, 6, [1], 4, true)

static func horned_hollow() -> ElementalChampionCardDefinition:
	return _make(CardNames.HORNED_HOLLOW, CardEnums.Element.TWIG, 6, 4, [1, 2], 6, false)

static func calamity_leopard() -> ElementalChampionCardDefinition:
	return _make(CardNames.CALAMITY_LEOPARD, CardEnums.Element.TWIG, 3, 8, [1, 2], 8, false)

# *** Pebbles ***

static func jade_titan() -> ElementalChampionCardDefinition:
	return _make(CardNames.JADE_TITAN, CardEnums.Element.PEBBLE, 3, 5, [1], 4, false)

static func boulderhide_brute() -> ElementalChampionCardDefinition:
	return _make(CardNames.BOULDERHIDE_BRUTE, CardEnums.Element.PEBBLE, 6, 6, [1, 2], 6, false)

static func oxen_avenger() -> ElementalChampionCardDefinition:
	return _make(CardNames.OXEN_AVENGER, CardEnums.Element.PEBBLE, 8, 7, [1, 2], 8, false)

# *** Leafs ***

static func agile_assailant() -> ElementalChampionCardDefinition:
	return _make(CardNames.AGILE_ASSAILANT, CardEnums.Element.LEAF, 3, 5, [2], 4, false)

static func bog_blight() -> ElementalChampionCardDefinition:
	return _make(CardNames.BOG_BLIGHT, CardEnums.Element.LEAF, 4, 5, [1], 6, true)

static func komodo_kin() -> ElementalChampionCardDefinition:
	return _make(CardNames.KOMODO_KIN, CardEnums.Element.LEAF, 8, 6, [1, 2], 8, false)

# *** Droplets ***

static func tide_turner() -> ElementalChampionCardDefinition:
	return _make(CardNames.TIDE_TURNER, CardEnums.Element.DROPLET, 4, 4, [1, 2], 4, false)

static func king_crustacean() -> ElementalChampionCardDefinition:
	return _make(CardNames.KING_CRUSTACEAN, CardEnums.Element.DROPLET, 3, 7, [1, 2], 6, false)

static func frostfall_emperor() -> ElementalChampionCardDefinition:
	return _make(CardNames.FROSTFALL_EMPEROR, CardEnums.Element.DROPLET, 2, 12, [1], 8, false)

static func _make(name: String, element: CardEnums.Element, attack: int, health: int,
		row_requirement: Array[int], level_requirement: int, is_daybreak: bool) -> ElementalChampionCardDefinition:
	var card := ElementalChampionCardDefinition.new()
	card.card_name = name
	card.price = 1
	card.is_starter = true
	card.element = element
	card.attack = attack
	card.health = health
	card.row_requirement = row_requirement
	card.level_requirement = level_requirement
	card.is_daybreak = is_daybreak
	return card
