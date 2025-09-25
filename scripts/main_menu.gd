extends Control

@export var solo : PackedScene
@export var online : PackedScene

func _ready():
	UIOverlay.get_node("IG UI").hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_solo_pressed():
	get_tree().change_scene_to_packed(solo)

func _on_online_pressed():
	get_tree().change_scene_to_packed(online)
