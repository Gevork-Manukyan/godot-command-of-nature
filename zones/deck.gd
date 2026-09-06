class_name Deck
extends CardZone

func shuffle() -> void:
	cards.shuffle()

## Draws the top card. If the deck is empty, shuffles the given discard pile
## into the deck first, per the rulebook ("shuffle your discard pile and
## place it face down to form a new deck, then draw a card"). Returns null
## only if both the deck and that discard pile are empty.
func draw(discard_pile: CardZone) -> CardDefinition:
	if is_empty():
		if discard_pile == null or discard_pile.is_empty():
			return null
		add_cards(discard_pile.take_all())
		shuffle()
	return cards.pop_back()

## Inserts cards at the bottom (opposite end from draw()), preserving their
## given order. Used by the Market "refresh" action, which cycles the
## currently-displayed cards to the bottom of that market's deck rather than
## discarding them.
func add_cards_to_bottom(new_cards: Array[CardDefinition]) -> void:
	var combined: Array[CardDefinition] = []
	combined.append_array(new_cards)
	combined.append_array(cards)
	cards = combined
