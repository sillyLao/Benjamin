extends Node3D

var character_scene : PackedScene = preload("res://scenes/Entities/character.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.is_host:
		for id in Global.players_dict:
			var new_player : CharacterBody3D = character_scene.instantiate()
			new_player.name = str(id)
			add_child(new_player)
