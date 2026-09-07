class_name Match
extends RefCounted

## Match-level orchestration: which side is taking its Turn right now,
## handing off to the other side when one ends, and the win condition.
##
## side_a/side_b are each 1 PlayerState (2-player) or 2 (a 4-player team),
## already built by PlayerSetup.new_player()/new_team() -- Match doesn't
## build rosters itself, just orchestrates turns across whatever sides it's
## given. Which side goes first (and therefore which side got 0 starting
## gold vs. 3/4, per PlayerSetup) is a real-world tiebreak the rulebook
## leaves outside the game state ("the player/team with the most house
## plants goes first") -- so Match takes first_side as an explicit
## parameter rather than re-deciding it.
##
## Win condition, per rules.pdf ("How to Win" / the Phase IV Sage-defeat
## section): a side loses once EVERY one of its Sages is defeated. In
## 2-player that's just the one Sage. In 4-player team mode, a teammate
## whose Sage falls keeps playing (their hand/deck/AP-pool access is
## unaffected) but permanently loses faction actions and leveling -- see
## PlayerState.level_up()/Turn.can_use_faction_action() -- while the match
## itself only ends once BOTH teammates' Sages have fallen.
##
## current_turn.opponents already gives whoever is building an EffectContext
## for the active side's action the correct "enemy formation" to target
## (current_turn.opponents[0].formation) -- no separate lookup needed here,
## even in 4-player, since each team has exactly one shared formation.

var side_a: Array[PlayerState]
var side_b: Array[PlayerState]
var active_side: int
var current_turn: Turn

func _init(p_side_a: Array[PlayerState], p_side_b: Array[PlayerState], first_side: int):
	side_a = p_side_a
	side_b = p_side_b
	active_side = first_side
	_start_turn()

func _start_turn() -> void:
	var acting := side_a if active_side == 0 else side_b
	var opposing := side_b if active_side == 0 else side_a
	current_turn = Turn.new(acting, opposing)

## -1 while ongoing, 0 if side_a has won (every one of side_b's Sages is
## defeated), 1 if side_b has won.
func winner() -> int:
	if _all_sages_defeated(side_b):
		return 0
	if _all_sages_defeated(side_a):
		return 1
	return -1

func is_over() -> bool:
	return winner() != -1

static func _all_sages_defeated(side: Array[PlayerState]) -> bool:
	for p in side:
		if p.sage == null or not p.sage.is_defeated():
			return false
	return true

## Ends the active side's turn and hands off to the other side, if the turn
## is actually over (Turn.phase == CLEANUP and every hand within limit --
## see Turn.can_end_cleanup(), which Turn.advance_phase() itself checks).
## Checks the win condition first: if the match is already over, no new
## Turn starts (current_turn stays as the final turn for inspection).
func finish_turn() -> bool:
	if current_turn.phase != Turn.Phase.CLEANUP or not current_turn.advance_phase():
		return false
	if is_over():
		return true
	active_side = 1 - active_side
	_start_turn()
	return true
