extends Node

var player_stats := {
	"max health": 3,
	"health": 3,
	"attack": 1
}

var enemy_stats := {
	"health": 5,
	"attack": 1
}

func reset_player_health() -> void:
	player_stats["health"] = player_stats["max_health"]
