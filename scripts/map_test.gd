extends Node3D

var character_scene : PackedScene = preload("res://scenes/Entities/character.tscn")
var available_respawns : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.is_host: # Server
		for node in get_node("Map/Respawns").get_children():
			available_respawns.append(node)
		spawn_players()
		Global.launch_online_game.rpc()
		

func spawn_players():
	for id in Global.players_dict:
		var new_player : CharacterBody3D = character_scene.instantiate()
		var n = randi_range(0, len(available_respawns)-1)
		var spawn_node = available_respawns.pop_at(n)
		new_player.position = spawn_node.position
		new_player.rotation = spawn_node.rotation
		new_player.name = str(id)
		print(spawn_node)
		add_child(new_player)

func check_respawns():
	available_respawns.clear()
	for node in get_node("Map/Respawns").get_children():
		if node.get_node("Timer").time_left == 0:
			available_respawns.append(node)

func respawn(id : int):
	check_respawns()
	var n = randi_range(0, len(available_respawns)-1)
	var respawn_node = available_respawns.pop_at(n)
	respawn_node.get_node("Timer").start()
	get_node(str(id)).respawn_at.rpc_id(id, respawn_node.name)
