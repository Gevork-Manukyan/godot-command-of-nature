class_name Market
extends RefCounted

const FACE_UP_COUNT := 3
const REFRESH_COST := 1
## Paying this on top of a bought Elemental's price brings it directly into
## your formation instead of your discard pile, if you have an empty space.
## Deciding whether to pay it -- and actually summoning the card -- is the
## caller's job, same as everywhere else in this codebase; Market only
## tracks its own deck/face-up state.
const ELEMENTAL_DIRECT_SUMMON_SURCHARGE := 2

var deck: Deck
var face_up: Array[CardDefinition] = []

func _init(cards: Array[CardDefinition]):
	deck = Deck.new()
	deck.add_cards(cards)
	deck.shuffle()
	_refill()

## All Elementals that don't belong to a Sage pack, per the rulebook -- since
## every Sage/Champion is always is_starter=true, filtering the whole card
## pool by type + is_starter naturally yields exactly the Basics/Warriors
## that qualify, with no need to special-case which categories to exclude.
static func new_elemental_market() -> Market:
	var cards: Array[CardDefinition] = []
	for card in CardLibrary.all():
		if card is ElementalCardDefinition and not card.is_starter:
			cards.append(card)
	return Market.new(cards)

## All Commands that don't belong to a Sage pack (Utilities are never part
## of one, so all 4 qualify).
static func new_command_market() -> Market:
	var cards: Array[CardDefinition] = []
	for card in CardLibrary.all():
		if card is ItemCardDefinition and not card.is_starter:
			cards.append(card)
	return Market.new(cards)

func _refill() -> void:
	while face_up.size() < FACE_UP_COUNT and not deck.is_empty():
		var drawn := deck.draw(null)
		if drawn == null:
			break
		face_up.append(drawn)

func can_afford(index: int, gold: GoldPool) -> bool:
	if index < 0 or index >= face_up.size():
		return false
	return gold.amount >= face_up[index].price

## Buys the face-up card at index, paying its price and refilling the empty
## slot from the deck. Returns the bought card, or null if the index is
## invalid or it can't be afforded -- callers should check can_afford()
## first rather than rely on this to signal failure. What happens to the
## card next (discard pile, or paying ELEMENTAL_DIRECT_SUMMON_SURCHARGE to
## summon it) is the caller's decision.
func buy(index: int, gold: GoldPool) -> CardDefinition:
	if not can_afford(index, gold):
		return null
	var card := face_up[index]
	gold.remove(card.price)
	face_up.remove_at(index)
	_refill()
	return card

func can_refresh(gold: GoldPool) -> bool:
	return gold.amount >= REFRESH_COST

## Moves all current face-up cards to the bottom of the deck (not lost --
## they'll come back around) and reveals REFRESH_COST new ones, per the
## rulebook. May be called multiple times per turn if affordable.
func refresh(gold: GoldPool) -> bool:
	if not can_refresh(gold):
		return false
	gold.remove(REFRESH_COST)
	deck.add_cards_to_bottom(face_up)
	face_up = []
	_refill()
	return true

## Gold collected for selling a card: half its price, rounded up. The
## rulebook states this generally, then separately notes Sage-pack cards
## always net exactly 1 gold when sold -- those two rules happen to agree
## for every is_starter card in this library (they're all price 1, and
## ceil(1/2) = 1), so one formula covers both without a special case.
static func sell_value(card: CardDefinition) -> int:
	return (card.price + 1) / 2
