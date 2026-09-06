class_name CardZone
extends RefCounted

## A plain, order-preserving collection of cards used for Hand, Discard Pile,
## and the Removed-From-Game pile (defeated Elementals and sold cards, per the
## rulebook, never return -- Deck is the only zone with extra behavior, see
## deck.gd). Holds CardDefinition, not CardInstance: a card's damage/shield/
## boost state only exists while it's on the Formation, and resets once it
## leaves (a fresh CardInstance gets created if it's summoned again later).

var cards: Array[CardDefinition] = []

func add(card: CardDefinition) -> void:
	cards.append(card)

func add_cards(new_cards: Array[CardDefinition]) -> void:
	cards.append_array(new_cards)

func remove_at(index: int) -> CardDefinition:
	if index < 0 or index >= cards.size():
		return null
	return cards.pop_at(index)

func remove_card(card: CardDefinition) -> bool:
	var index := cards.find(card)
	if index == -1:
		return false
	cards.remove_at(index)
	return true

func get_all() -> Array[CardDefinition]:
	return cards

func take_all() -> Array[CardDefinition]:
	var taken := cards
	cards = []
	return taken

func size() -> int:
	return cards.size()

func is_empty() -> bool:
	return cards.is_empty()

func clear() -> void:
	cards = []
