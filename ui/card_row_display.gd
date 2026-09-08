class_name CardRowDisplay
extends HBoxContainer

## Visualizes a flat list of cards as a horizontal row of CardDisplay
## instances -- a player's hand or discard pile (set_zone(), a CardZone),
## or a Market's face-up listing (set_cards(market.face_up), a plain
## Array[CardDefinition] -- Market isn't a CardZone). No live CardInstance
## per card here (hand/discard/market cards are just CardDefinitions, not
## yet CardInstances on a board), so each CardDisplay renders without
## damage/shield/boost overlays. Doesn't add its own click handling, but
## each CardDisplay child's `pressed` signal is still there for a caller to
## connect to after every set_cards()/set_zone() call (see GameScreen).

const CARD_SCENE: PackedScene = preload("res://ui/card_display.tscn")

func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)

func set_cards(cards: Array[CardDefinition]) -> void:
	# remove_child() (not just queue_free()) so get_children()/
	# get_child_count() reflect the new set immediately -- queue_free()
	# alone defers removal to end-of-frame, so a caller re-querying
	# children right after this call (e.g. to reconnect signals) would
	# still see the stale ones too. Still queue_free() rather than free()
	# outright, since this can run from inside a child's own signal
	# handler (a card click triggering a refresh) -- freeing it
	# synchronously mid-signal would be unsafe.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for card in cards:
		var display: CardDisplay = CARD_SCENE.instantiate()
		add_child(display)
		display.set_card(card)

func set_zone(zone: CardZone) -> void:
	set_cards(zone.get_all() if zone != null else ([] as Array[CardDefinition]))
