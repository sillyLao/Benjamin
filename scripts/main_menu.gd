extends Control

@export var solo : PackedScene
@export var online : PackedScene

func _ready():
	UIOverlay.get_node("IG UI").hide()
	UIOverlay.get_node("PauseMenu").hide()
	UIOverlay.get_node("GameEnded").hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.players_dict.clear()
	for child in UIOverlay.tab.get_children():
		if not child.name == "Head":
			child.queue_free()
	Global.players_score.clear()
	if not UIOverlay.menu_music.playing:
		UIOverlay.menu_music.play()
		if randf() <= 0.01:
			UIOverlay.menu_music.pitch_scale = 1.2

func _on_solo_pressed():
	get_tree().change_scene_to_packed(solo)

func _on_online_pressed():
	get_tree().change_scene_to_packed(online)
