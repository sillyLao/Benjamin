extends Control

@onready var ammos = $"IG UI/Ammos/Label"
@onready var ammos_progress = $"IG UI/Ammos/ProgressBar"
@onready var scale_bar = $"IG UI/ScaleBar/ProgressBar"
@onready var animation_player = $AnimationPlayer
@onready var tab = $"IG UI/Tab/VBoxContainer"

var kill_methods : Dictionary = {
	"shrink" : "res://assets/ui/kill_shrink.png",
	"crush" : "res://assets/ui/kill_crush.png",
	"crushed_self" : "res://assets/ui/kill_crushed_self.png",
}
var self_player : CharacterBody3D

var notification_scene : PackedScene = preload("res://scenes/UI/notification.tscn")
var kill_line_scene : PackedScene = preload("res://scenes/UI/kill_line.tscn")
var hit_pos_indicator_scene : PackedScene = preload("res://scenes/UI/hit_position_indicator.tscn")

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

func spawn_hit_pos_indicator(pos: Vector3):
	var hpi = hit_pos_indicator_scene.instantiate()
	hpi.pos = pos
	$"IG UI/HitPos".add_child(hpi)

func _physics_process(_delta):
	if $"IG UI/HitPos".get_children():
		for child in $"IG UI/HitPos".get_children():
			child.rotation = Vector2(self_player.position.x, self_player.position.z).angle_to_point(Vector2(child.pos.x, child.pos.z))
			print(Vector2(self_player.position.x, self_player.position.z).angle_to_point(Vector2(child.pos.x, child.pos.z)))

func _unhandled_key_input(event):
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
