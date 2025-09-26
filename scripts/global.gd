extends Node


var paused : bool = false
var in_game : bool = false


func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel") and in_game:
		if Global.paused:
			Global.paused = false
			UIOverlay.get_node("PauseMenu").hide()
		else:
			Global.paused = true
			UIOverlay.get_node("PauseMenu").show()

func switch_to_game():
	UIOverlay.get_node("IG UI").show()


# ---- ONLINE ----

signal player_quits(id: int)

var pseudo : String
var server_ip : String
var is_host : bool
var peer : ENetMultiplayerPeer
var players_dict : Dictionary
var players_score : Dictionary
var player_count : int = 0
var leave_reason : String


@rpc("authority", "call_local", "reliable")
func launch_online_game():
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	for id in players_dict:
		players_score[id] = {}
		players_score[id]["kills"] = 0
		players_score[id]["deaths"] = 0

func _peer_disconnected(id):
	if not id == 1:
		UIOverlay.spawn_notification({
			"icon" : "res://icon.svg",
			"text" : Global.players_dict[id]["pseudo"] + " disconnected from the lobby.",
			"timer" : 5
		})
	if is_host:
		player_quits.emit(id)

func _server_disconnected():
	if not Global.is_host:
		match leave_reason:
			"voluntary":
				leave_reason = ""
			_:
				UIOverlay.spawn_notification({
					"icon" : "res://icon.svg",
					"text" : Global.players_dict[1]["pseudo"] + " closed the lobby.",
					"timer" : 5
				})
				get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")

@rpc("any_peer", "call_local", "reliable")
func add_kill_death(kill: int, death: int):
	if kill:
		players_score[kill]["kills"] += 1
		UIOverlay.tab.get_node(str(kill) + "/MarginContainer/HBoxContainer/Kills").text = str(players_score[kill]["kills"])
	if death:
		players_score[death]["deaths"] += 1
		UIOverlay.tab.get_node(str(death) + "/MarginContainer/HBoxContainer/Deaths").text = str(players_score[death]["deaths"])
