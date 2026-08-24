extends Button

signal card_selected(card)

func _ready():
	toggle_mode = true
	toggled.connect(_on_toggled)

func _on_toggled(is_selected: bool):
	if is_selected:
		modulate = Color(1.0, 1.0, 0.65)
		card_selected.emit(self)
	else:
		modulate = Color.WHITE
