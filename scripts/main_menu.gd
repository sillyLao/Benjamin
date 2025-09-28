extends Control

@export var solo : PackedScene
@export var online : PackedScene

func _ready():
	UIOverlay.get_node("IG UI").hide()
	UIOverlay.get_node("PauseMenu").hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.players_dict.clear()
	for child in UIOverlay.tab.get_children():
		child.queue_free()
	Global.players_score.clear()
	UIOverlay.get_node("MenuMusic").play()
	if randf() <= 0.01:
		UIOverlay.get_node("MenuMusic").pitch_scale = 1.2

func _on_solo_pressed():
	get_tree().change_scene_to_packed(solo)

func _on_online_pressed():
	get_tree().change_scene_to_packed(online)
