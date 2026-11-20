class_name MatchScore
extends RefCounted

const WINS_REQUIRED := 2
var wins := [0, 0]
var last_winner := -1

func reset() -> void:
	wins = [0, 0]
	last_winner = -1

func record(outcome: int) -> bool:
	if finished() or outcome not in [0, 1, 2]: return false
	last_winner = outcome
	if outcome < 2: wins[outcome] += 1
	return true

func finished() -> bool:
	return wins[0] >= WINS_REQUIRED or wins[1] >= WINS_REQUIRED

func winner() -> int:
	return 0 if wins[0] >= WINS_REQUIRED else 1 if wins[1] >= WINS_REQUIRED else -1

func next_number() -> int:
	# Draws replay the same call. Final Down only follows a 1–1 score.
	return mini(wins[0] + wins[1] + 1, 3)
