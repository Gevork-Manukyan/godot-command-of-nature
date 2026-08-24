extends Control

const CARD_SCENE = preload("res://card.tscn")

const SUITS = ["♠", "♥", "♦", "♣"]
const RANKS = [
	"A", "2", "3", "4", "5", "6", "7",
	"8", "9", "10", "J", "Q", "K"
]

var deck = []
var selected_card: Button = null


func _ready():
	$PlayCardButton.pressed.connect(_on_play_card_pressed)

	create_deck()
	deal_starting_hands()

	print("Cards remaining in deck: ", deck.size())


func create_deck():
	deck.clear()

	for suit in SUITS:
		for rank in RANKS:
			var card_data = {
				"rank": rank,
				"suit": suit
			}

			deck.append(card_data)

	deck.shuffle()


func deal_starting_hands():
	for i in range(5):
		deal_card($PlayerHand, true)
		deal_card($OpponentHand, false)


func deal_card(hand: HBoxContainer, is_player: bool):
	if deck.is_empty():
		return

	var card_data = deck.pop_back()
	var card = CARD_SCENE.instantiate()

	if is_player:
		card.text = card_data["rank"] + card_data["suit"]
		card.card_selected.connect(_on_card_selected)
	else:
		card.text = "??"
		card.disabled = true

	hand.add_child(card)


func _on_card_selected(card: Button):
	if selected_card != null and selected_card != card:
		selected_card.button_pressed = false

	selected_card = card

	print("Game selected: ", card.text)


func _on_play_card_pressed():
	if selected_card == null:
		print("Select a card first.")
		return

	print("Played: ", selected_card.text)

	selected_card.button_pressed = false
	selected_card.reparent($PlayArea)
	selected_card.disabled = true

	selected_card = null
