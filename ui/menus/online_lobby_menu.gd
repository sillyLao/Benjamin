extends Control

var back_pressed : bool = false
var checkmark = preload("res://assets/ui/check.png")

var selected_character : String = "benjamin"
var selected_weapon : String = "blaster1"
var selected_movement : String = "dash"
var selected_item : String = "mine"
var selected_pet : String = "rubber_duck"

func _ready():
	hide_customize()
	update_ready()
	send_game_settings(Global.game_settings)
	$WeaponSelectionScreen.hide()
	if Global.players_dict:
		if Global.players_dict[multiplayer.get_unique_id()]["ready"]:
			$Ready.button_pressed = true
			block_customize()
	if Global.is_host: # Server
		if Global.new_lobby:
			multiplayer.peer_connected.connect(_peer_connected)
			multiplayer.peer_disconnected.connect(_peer_disconnected)
			var infos = create_infos()
			Global.player_count += 1
			Global.players_dict[multiplayer.get_unique_id()] = infos
		update_player_list.rpc(Global.players_dict)
	
	else: # Client
		$GameSettings/List/VBoxContainer/Edit.hide()
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
		get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")

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
		get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
	else: # Client
		Global.peer.close()
		get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
		

func _on_start_game_pressed():
	if Global.is_host:
		start_game.rpc()

@rpc("authority", "call_local", "reliable")
func start_game():
	Global.in_game = true
	Global.switch_to_game()
	get_tree().change_scene_to_file("res://maps/Labpark.tscn")


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
	send_ready_infos.rpc(multiplayer.get_unique_id(), get_ready_infos())
	block_customize()

func get_ready_infos() -> Dictionary:
	var infos = {
		"laser_color": Color.WHITE,
		"character": selected_character,
	}
	infos["laser_color"] = $Customize/OptionsPanel/MarginContainer/HBoxContainer/L/LaserColor/ColorPickerButton.color
	infos["character"] = selected_character
	infos["weapon"] = selected_weapon
	infos["movement"] = selected_movement
	infos["item"] = selected_item
	infos["pet"] = selected_pet
	return infos

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
func send_ready_infos(id : int, infos : Dictionary):
	if Global.is_host:
		for key in infos.keys():
			Global.players_dict[id][key] = infos[key]
		update_player_list.rpc(Global.players_dict)

@rpc("authority", "call_local", "reliable")
func send_game_settings(game_settings: Dictionary):
	Global.game_settings = game_settings.duplicate()
	for key in game_settings:
		$GameSettings/List/VBoxContainer.get_node(key).get_node("Label").text = str(game_settings[key])
	if game_settings["Teams"] == "No teams":
		$GameSettings/List/VBoxContainer/Teams.hide()
	match game_settings["WinCon"]:
		"Time":
			$GameSettings/List/VBoxContainer/Score.hide()
			$GameSettings/List/VBoxContainer/Time.show()
			UIOverlay.game_timer.wait_time = game_settings["Time"]
			UIOverlay.game_timer.get_parent().show()
		"Score":
			$GameSettings/List/VBoxContainer/Score.show()
			$GameSettings/List/VBoxContainer/Time.hide()
			UIOverlay.game_timer.get_parent().hide()


func _on_edit_pressed():
	$GameSettings/List.hide()
	$GameSettings/Edit.show()

func _on_ok_pressed():
	$GameSettings/List.show()
	$GameSettings/Edit.hide()
	var settings1 := ["GameMode", "Format", "Teams", "WinCon", "Map"]
	var game_settings := {}
	for key in settings1:
		var ob : OptionButton = $GameSettings/Edit/VBoxContainer.get_node(key +"/OptionButton")
		game_settings[key] = ob.get_item_text(ob.selected)
	if game_settings["Format"] == "Free for all":
		game_settings["Teams"] = "No teams"
	var settings2 := ["Time", "Score"]
	for key in settings2:
		var le : LineEdit = $GameSettings/Edit/VBoxContainer.get_node(key +"/LineEdit")
		game_settings[key] = int(le.text)
	send_game_settings.rpc(game_settings)

func block_customize() -> void:
	$Customize/Button.disabled = !$Customize/Button.disabled

func show_customize() -> void:
	$Customize/OptionsPanel.show()
	$Customize/Shade.show()
	$Customize/OK.show()
	

func hide_customize() -> void:
	$Customize/OptionsPanel.hide()
	$Customize/Shade.hide()
	$Customize/OK.hide()

func _on_customize_pressed():
	show_customize()
func _on_customize_ok_pressed():
	hide_customize()


func _on_character_pressed():
	pass # Replace with function body.

func _on_weapon_pressed():
	hide_customize()
	$WeaponSelectionScreen.show()
	if Global.players_dict[multiplayer.get_unique_id()].find_key("weapon"):
		$WeaponSelectionScreen.switch_to_weapon(Global.players_dict[multiplayer.get_unique_id()]["weapon"])

func _on_movement_pressed():
	pass # Replace with function body.

func _on_item_pressed():
	pass # Replace with function body.

func _on_pet_pressed():
	pass # Replace with function body.

func switch_character() -> void:
	pass

func switch_weapon(weapon) -> void:
	selected_weapon = weapon
	$Customize/OptionsPanel/MarginContainer/HBoxContainer/R/HBoxContainer/Weapon.texture_normal = load("res://assets/ui/weapons_icons/"+selected_weapon.to_lower()+".png")
	show_customize()

func switch_movement() -> void:
	pass

func switch_item() -> void:
	pass

func switch_pet() -> void:
	pass
