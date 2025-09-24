extends Control

var back_pressed : bool = false

func _ready():
	if Global.is_host: # Server
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		var infos = create_infos()
		infos["order"] = Global.player_count
		Global.player_count += 1
		Global.players_dict[multiplayer.get_unique_id()] = infos
		update_player_list.rpc(Global.players_dict)
	
	else: # Client
		multiplayer.connected_to_server.connect(_connected_to_server)
		multiplayer.server_disconnected.connect(_server_disconnected)

func _peer_connected(id : int):
	print("["+str(multiplayer.get_unique_id())+"]  " + str(id) + " connected.")

func _peer_disconnected(id : int):
	Global.players_dict.erase(id)
	update_player_list.rpc(Global.players_dict)

func _connected_to_server():
	print("["+str(multiplayer.get_unique_id())+"]  Connected to server.")
	var infos = create_infos()
	send_infos.rpc(multiplayer.get_unique_id(), infos)

func _server_disconnected():
	if not back_pressed:
		UIOverlay.spawn_notification({
			"icon" : "res://icon.svg",
			"text" : Global.players_dict[1]["pseudo"] + " closed the lobby.",
			"timer" : 5
		})
		Global.peer.close()
		get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")

func create_infos() -> Dictionary:
	var dict = {
		"pseudo" = Global.pseudo,
	}
	return dict

@rpc("any_peer", "call_local", "reliable")
func update_player_list(players_dict : Dictionary):
	Global.players_dict = players_dict.duplicate(true)
	for child in $PanelContainer/VBoxContainer.get_children():
		child.queue_free()
	for key in players_dict:
		var label = Label.new()
		label.text = players_dict[key]["pseudo"]
		$PanelContainer/VBoxContainer.add_child(label)

@rpc("any_peer", "call_remote", "reliable")
func send_infos(id:int, infos:Dictionary):
	if Global.is_host:
		infos["order"] = Global.player_count
		Global.player_count += 1
		Global.players_dict[id] = infos
		update_player_list.rpc(Global.players_dict)
	

func _on_back_pressed():
	back_pressed = true
	if Global.is_host: # Server
		Global.peer.close()
		Global.players_dict.clear()
		get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")
	else: # Client
		Global.peer.close()
		get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")
		

func _on_start_game_pressed():
	if Global.is_host:
		start_game.rpc()

@rpc("authority", "call_local", "reliable")
func start_game():
	get_tree().change_scene_to_file("res://scenes/Game/map_test.tscn")


func _on_copy_ip_pressed():
	DisplayServer.clipboard_set(Global.server_ip)
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : "IP copied to clipboard !",
		"timer" : 1.5
	})
