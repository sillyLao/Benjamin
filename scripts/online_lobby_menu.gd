extends Control

var back_pressed : bool = false
var checkmark = preload("res://assets/ui/check.png")

func _ready():
	$Options/BlockOptions.hide()
	update_ready()
	if Global.is_host: # Server
		if Global.new_lobby:
			multiplayer.peer_connected.connect(_peer_connected)
			multiplayer.peer_disconnected.connect(_peer_disconnected)
			var infos = create_infos()
			Global.player_count += 1
			Global.players_dict[multiplayer.get_unique_id()] = infos
		update_player_list.rpc(Global.players_dict)
	
	else: # Client
		if Global.new_lobby:
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
		"order" = 1,
		"ready" = false
	}
	return dict

@rpc("any_peer", "call_local", "reliable")
func update_player_list(players_dict : Dictionary):
	Global.players_dict = players_dict.duplicate(true)
	for child in $PlayerList/MarginContainer/VBoxContainer.get_children():
		child.queue_free()
	for key in players_dict:
		add_player(key)
	update_ready()

func add_player(id: int):
	var label = Label.new()
	label.text = Global.players_dict[id]["pseudo"]
	var hbc = HBoxContainer.new()
	hbc.custom_minimum_size.y = 25
	var tx = TextureRect.new()
	tx.texture = checkmark
	tx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tx.custom_minimum_size.x = 25
	$PlayerList/MarginContainer/VBoxContainer.add_child(hbc)
	hbc.add_child(label)
	hbc.add_child(tx)
	tx.visible = Global.players_dict[id]["ready"]

@rpc("any_peer", "call_remote", "reliable")
func send_infos(id:int, infos:Dictionary):
	if Global.is_host:
		infos["order"] = Global.player_count
		infos["ready"] = false
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
	Global.in_game = true
	Global.switch_to_game()
	get_tree().change_scene_to_file("res://scenes/Game/map_test.tscn")


func _on_copy_ip_pressed():
	DisplayServer.clipboard_set(Global.server_ip)
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : "IP copied to clipboard !",
		"timer" : 1.5
	})

@rpc("any_peer", "call_local", "reliable")
func set_ready(id: int, is_ready : bool):
	Global.players_dict[id]["ready"] = is_ready

func _on_ready_toggled(toggled_on):
	set_ready.rpc(multiplayer.get_unique_id(), toggled_on)
	send_ready_infos.rpc(multiplayer.get_unique_id(), $Options/HBoxContainer/ColorPickerButton.color)
	$Options/BlockOptions.visible = toggled_on

func update_ready():
	var n := 0
	for id in Global.players_dict:
		if Global.players_dict[id]["ready"]:
			n += 1
	if n == len(Global.players_dict):
		if Global.is_host:
			$StartGame.disabled = false
			$StartGame.text = "Start"
		else:
			$StartGame.text = "Waiting for host..."
	else:
		$StartGame.disabled = true
		$StartGame.text = str(n)+"/"+str(len(Global.players_dict))+" ready"

@rpc("any_peer", "call_local", "reliable")
func send_ready_infos(id:int, laser_color: Color):
	if Global.is_host:
		Global.players_dict[id]["laser_color"] = laser_color
		update_player_list.rpc(Global.players_dict)
