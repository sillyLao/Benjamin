extends Node

# ---- ONLINE ----
var pseudo : String
var server_ip : String
var is_host : bool
var peer : ENetMultiplayerPeer

var players_dict : Dictionary
var player_count : int = 0

@rpc("authority", "call_local", "reliable")
func launch_online_game():
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _peer_disconnected(id):
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : Global.players_dict[id]["pseudo"] + " disconnected from the lobby.",
		"timer" : 5
	})

func _server_disconnected():
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : Global.players_dict[1]["pseudo"] + " closed the lobby.",
		"timer" : 5
	})
	get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")
