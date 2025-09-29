extends Node3D

var character_scene : PackedScene = preload("res://scenes/Entities/character.tscn")
var available_respawns : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.is_host: # Server
		Global.player_quits.connect(_on_player_quits)
		for node in get_node("Map/Respawns").get_children():
			available_respawns.append(node)
		spawn_players()
		Global.launch_online_game.rpc()
	Global.current_map = self

func spawn_players():
	var spawn_dict : Dictionary
	for id in Global.players_dict:
		var new_player : CharacterBody3D = character_scene.instantiate()
		spawn_dict[id] = {}
		new_player.name = str(id)
		add_child(new_player)
	assign_spawn(spawn_dict)

func assign_spawn(spawn_dict: Dictionary):
	var quintus : bool
	if not spawn_dict:
		quintus = true
	for id in Global.players_dict:
		if quintus:
			spawn_dict[id] = {}
		var n = randi_range(0, len(available_respawns)-1)
		var spawn_node = available_respawns.pop_at(n)
		spawn_dict[id]["node"] = spawn_node.name
	assign_spawn_node.rpc(spawn_dict)

@rpc("authority", "call_local", "reliable")
func assign_spawn_node(dict: Dictionary):
	get_node(str(multiplayer.get_unique_id())).spawn_node = get_node("Map/Respawns/"+dict[multiplayer.get_unique_id()]["node"])
	get_node(str(multiplayer.get_unique_id())).position_spawn()

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

func _on_player_quits(id: int):
	get_node(str(id)).queue_free()
