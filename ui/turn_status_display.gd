class_name TurnStatusDisplay
extends VBoxContainer

## Read-only HUD for a Turn: phase, AP remaining/max, the acting side's
## shared gold, and each player's level + unlocked faction-action levels.
## Level is individual per player even in 4-player team mode (see
## PlayerState) -- so a team's status shows both teammates' levels
## separately, not one shared number, same as gold shows once since it
## really is the same shared GoldPool object either way (see Turn._gold()).
## No interactivity -- just reflects whatever Turn it's pointed at.

var turn: Turn

func _init() -> void:
	add_theme_constant_override("separation", 4)

func set_turn(new_turn: Turn) -> void:
	turn = new_turn
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	if turn == null:
		return

	var phase_label := Label.new()
	phase_label.text = "Phase: %s" % Turn.Phase.keys()[turn.phase]
	add_child(phase_label)

	var max_ap := Turn.MAX_AP_2_PLAYER if turn.players.size() == 1 else Turn.MAX_AP_4_PLAYER
	var ap_label := Label.new()
	ap_label.text = "AP: %d / %d" % [turn.ap_remaining, max_ap]
	add_child(ap_label)

	var gold: GoldPool = turn.players[0].gold
	var gold_label := Label.new()
	gold_label.text = "Gold: %d / %d" % [gold.amount, gold.max_amount]
	add_child(gold_label)

	for i in range(turn.players.size()):
		var p: PlayerState = turn.players[i]
		var suffix := "" if turn.players.size() == 1 else " (Player %d)" % (i + 1)
		var level_label := Label.new()
		level_label.text = "Level: %d%s" % [p.level, suffix]
		add_child(level_label)
		if not p.unlocked_faction_action_levels.is_empty():
			var unlocked_label := Label.new()
			unlocked_label.text = "  Unlocked faction actions: %s" % [p.unlocked_faction_action_levels]
			add_child(unlocked_label)
