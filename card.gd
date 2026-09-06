extends Button

signal card_selected(card)

var rank: String
var suit: String
var face_up: bool = true


func _ready():
	toggle_mode = true
	toggled.connect(_on_toggled)


func setup(new_rank: String, new_suit: String, is_face_up: bool):
	rank = new_rank
	suit = new_suit
	face_up = is_face_up

	update_display()


func update_display():
	if face_up:
		text = rank + suit
		disabled = false
	else:
		text = "??"
		disabled = true


func _on_toggled(is_selected: bool):
	if is_selected:
		modulate = Color(1.0, 1.0, 0.65)
		card_selected.emit(self)
	else:
		modulate = Color.WHITE
