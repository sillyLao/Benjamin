extends Control

@export var solo : PackedScene
@export var online : PackedScene

func _on_solo_pressed():
	get_tree().change_scene_to_packed(solo)

func _on_online_pressed():
	get_tree().change_scene_to_packed(online)
