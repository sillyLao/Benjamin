extends Control

var notification_scene : PackedScene = preload("res://scenes/UI/notification.tscn")

func spawn_notification(infos : Dictionary) -> void:
	var notif = notification_scene.instantiate()
	notif.get_node("VBoxContainer/MarginContainer/HBoxContainer/TextureRect").texture = load(infos["icon"])
	notif.get_node("VBoxContainer/MarginContainer/HBoxContainer/RichTextLabel").text = infos["text"]
	notif.get_node("Timer").wait_time = infos["timer"]
	$Notifications/VBoxContainer.add_child(notif)

#func _input(event):
	#if event.is_action_pressed("right"):
		#var new_notif = {
			#"icon" : "res://icon.svg",
			#"text" : "Got voteeeed xD xd",
			#"timer" : 2
		#}
		#spawn_notification(new_notif)
