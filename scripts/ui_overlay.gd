extends Control

@onready var ammos = $"IG UI/Ammos/Label"
@onready var ammos_progress = $"IG UI/Ammos/ProgressBar"
@onready var scale_bar = $"IG UI/ScaleBar/ProgressBar"
@onready var animation_player = $AnimationPlayer
@onready var tab = $"IG UI/Tab/VBoxContainer"
@onready var menu_music = $MenuMusic
@onready var game_timer = $"IG UI/Time/Timer"

var kill_methods : Dictionary = {
	"shrink" : "res://assets/ui/kill_shrink.png",
	"crush" : "res://assets/ui/kill_crush.png",
	"crushed_self" : "res://assets/ui/kill_crushed_self.png",
}
var self_player : CharacterBody3D

var notification_scene : PackedScene = preload("res://scenes/UI/notification.tscn")
var kill_line_scene : PackedScene = preload("res://scenes/UI/kill_line.tscn")
var hit_pos_indicator_scene : PackedScene = preload("res://scenes/UI/hit_position_indicator.tscn")
var tab_line_scene : PackedScene = preload("res://scenes/UI/tab_line.tscn")
var checkmark : CompressedTexture2D = preload("res://assets/ui/check.png")

func _ready():
	$"IG UI".hide()
	$PauseMenu.hide()

func spawn_notification(infos : Dictionary) -> void:
	var notif = notification_scene.instantiate()
	notif.get_node("VBoxContainer/MarginContainer/HBoxContainer/TextureRect").texture = load(infos["icon"])
	notif.get_node("VBoxContainer/MarginContainer/HBoxContainer/RichTextLabel").text = infos["text"]
	notif.get_node("Timer").wait_time = infos["timer"]
	$Notifications/VBoxContainer.add_child(notif)

@rpc("any_peer", "call_local", "reliable")
func spawn_kill_line(killer: int, victim: int, method: String) -> void:
	var kill_line = kill_line_scene.instantiate()
	if killer:
		kill_line.get_node("Killer").text = Global.players_dict[killer]["pseudo"]
	else:
		kill_line.get_node("Killer").text = ""
	kill_line.get_node("Victim").text = Global.players_dict[victim]["pseudo"]
	kill_line.get_node("TextureRect").texture = load(kill_methods[method])
	$"IG UI/KillsList".add_child(kill_line)

func spawn_hit_pos_indicator(pos: Vector3, color: Color):
	var hpi = hit_pos_indicator_scene.instantiate()
	hpi.pos = pos
	hpi.modulate = color
	$"IG UI/HitPos".add_child(hpi)

func create_tab():
	for id in Global.players_dict:
		var tab_line = tab_line_scene.instantiate()
		tab_line.get_node("MarginContainer/HBoxContainer/Name").text = Global.players_dict[id]["pseudo"]
		tab_line.get_node("MarginContainer/HBoxContainer/LaserColor").color = Global.players_dict[id]["laser_color"]
		tab_line.name = str(id)
		UIOverlay.tab.add_child(tab_line)
		UIOverlay.tab.add_child(HSeparator.new())

func _physics_process(_delta):
	if $"IG UI/HitPos".get_children():
		for child in $"IG UI/HitPos".get_children():
			#child.rotation = Vector2(self_player.position.x, self_player.position.z).angle_to_point(Vector2(child.pos.x, child.pos.z)))
			var cam_direction = self_player.camera.get_global_transform().basis.z
			var cam_vect = Vector2(cam_direction.x, -cam_direction.z).normalized()
			var shoot_vect = Vector2((-child.pos.x+self_player.global_position.x),(child.pos.z-self_player.global_position.z)).normalized()
			var angle = cam_vect.angle_to(shoot_vect)
			child.rotation = -angle
			print(child.rotation)
			print(Vector2(-child.pos.x, child.pos.z))#.normalized())
			print(Vector2(-self_player.global_position.x, self_player.global_position.z))#.normalized())
	if Global.in_game:
		$"IG UI/Time".text = str(snapped($"IG UI/Time/Timer".time_left, 0.01))

func _unhandled_key_input(event):
	if not Global.paused:
		if event.is_action_pressed("tab"):
			$"IG UI/Tab".show()
		if event.is_action_released("tab"):
			$"IG UI/Tab".hide()
	#if event.is_action_pressed("right"):
		#UIOverlay.spawn_notification({
			#"icon": "res://icon.svg",
			#"text": "GOT VOOTEED",
			#"timer": 3
		#})

func _on_resume_pressed():
	$PauseMenu.hide()
	Global.paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_options_pressed():
	pass # Replace with function body.

func _on_quit_pressed():
	$PauseMenu.hide()
	Global.paused = false
	Global.leave_reason = "voluntary"
	if Global.is_host: # Server
		Global.peer.close()
		Global.players_dict.clear()
		get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")
	else: # Client
		Global.peer.close()
		get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")

func _on_timer_timeout():
	end_game()

func end_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$PauseMenu.hide()
	$"IG UI".hide()
	Global.paused = true
	for child in $GameEnded/PlayerList/MarginContainer/VBoxContainer.get_children():
		child.name = str(randf())
		child.queue_free()
	for id in Global.players_dict:
		Global.players_dict[id]["ready"] = false
		add_player(id)
	var scoreboard = $"IG UI/Tab".duplicate()
	$GameEnded/Tab.add_child(scoreboard)
	scoreboard.position = Vector2.ZERO
	scoreboard.show()
	$GameEnded.show()

func add_player(id: int):
	var label = Label.new()
	label.text = Global.players_dict[id]["pseudo"]
	var hbc = HBoxContainer.new()
	hbc.custom_minimum_size.y = 25
	hbc.name = str(id)
	print(str(id))
	var tx = TextureRect.new()
	tx.texture = checkmark
	tx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tx.custom_minimum_size.x = 25
	$GameEnded/PlayerList/MarginContainer/VBoxContainer.add_child(hbc)
	hbc.add_child(label)
	hbc.add_child(tx)
	tx.visible = Global.players_dict[id]["ready"]

@rpc("any_peer", "call_local", "reliable")
func set_ready(id: int):
	Global.players_dict[id]["ready"] = true
	get_node("GameEnded/PlayerList/MarginContainer/VBoxContainer/"+str(id)).get_child(1).show()
	update_ready()

func _on_continue_pressed():
	set_ready.rpc(multiplayer.get_unique_id())

func update_ready():
	var n := 0
	for id in Global.players_dict:
		if Global.players_dict[id]["ready"]:
			n += 1
	if n == len(Global.players_dict):
		if Global.is_host:
			Global.launch_online_game.rpc()

func _on_lobby_pressed():
	quit_to_lobby.rpc()

@rpc("any_peer", "call_local", "reliable")
func quit_to_lobby():
	Global.new_lobby = false
	$GameEnded.hide()
	get_tree().change_scene_to_file("res://scenes/Menu/online_lobby_menu.tscn")

func start_game():
	for child in UIOverlay.tab.get_children():
		if not child.name == "Head":
			child.name = str(randf())
			child.queue_free()
	create_tab()
	Global.paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_music.stop()
	$GameEnded.hide()
	$"IG UI".show()
	game_timer.wait_time = 300
	game_timer.start()
	if Global.is_host:
		if Global.current_map:
			Global.current_map.assign_spawn({})
