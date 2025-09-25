extends Control

@onready var ammos = $"IG UI/Ammos/Label"
@onready var ammos_progress = $"IG UI/Ammos/ProgressBar"

var notification_scene : PackedScene = preload("res://scenes/UI/notification.tscn")

func _ready():
	$"IG UI".hide()
	$PauseMenu.hide()

func spawn_notification(infos : Dictionary) -> void:
	var notif = notification_scene.instantiate()
	notif.get_node("VBoxContainer/MarginContainer/HBoxContainer/TextureRect").texture = load(infos["icon"])
	notif.get_node("VBoxContainer/MarginContainer/HBoxContainer/RichTextLabel").text = infos["text"]
	notif.get_node("Timer").wait_time = infos["timer"]
	$Notifications/VBoxContainer.add_child(notif)

#func _input(event):
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
