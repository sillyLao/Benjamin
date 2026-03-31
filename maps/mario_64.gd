extends Node3D

@onready var pets = $Pets


var character_scene : PackedScene = preload("res://characters/benjamin.tscn")
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
	$"Map/Kill Zone".area_entered.connect(_on_kill_zone_area_entered)

func spawn_players():
	var spawn_dict : Dictionary
	for id in Global.players_dict:
		var new_player : CharacterBody3D = character_scene.instantiate()
		spawn_dict[id] = {}
		new_player.name = str(id)
		new_player.map = self
		add_child(new_player)
	assign_spawn(spawn_dict)

func assign_spawn(spawn_dict: Dictionary):
	for id in Global.players_dict:
		if not spawn_dict:
			spawn_dict[id] = {}
		var n = randi_range(0, len(available_respawns)-1)
		var spawn_node = available_respawns.pop_at(n)
		spawn_dict[id]["node"] = spawn_node.name
		print("["+str(id)+"] " + spawn_node.name)
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
	print("["+str(id)+"] " + respawn_node.name)
	get_node(str(id)).respawn_at.rpc_id(id, respawn_node.name)

func _on_player_quits(id: int):
	get_node(str(id)).queue_free()

#func equip_weapon(player, id):
	#print("[" + str(multiplayer.get_unique_id()) + "] id : " + str(id) + " | player : " + str(player) + " | authority : " + str(player.is_multiplayer_authority()))
	#var path = load("res://weapons/" + Global.players_dict[id]["weapon"].to_snake_case() + ".tscn")
	#var weapon = path.instantiate()
	#player.add_child(weapon)
	#player.blaster = weapon


func _on_kill_zone_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.fell_to_death()

func _on_mav_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.teleport($"Map/Teleports/Out/sno".global_position, $"Map/Teleports/Out/sno".rotation)

func _on_bob_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.teleport($"Map/Teleports/Out/wat".global_position, $"Map/Teleports/Out/wat".rotation)

func _on_bow_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.teleport($"Map/Teleports/Out/pea".global_position, $"Map/Teleports/Out/pea".rotation)

func _on_toa_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.teleport($"Map/Teleports/Out/dst".global_position, $"Map/Teleports/Out/dst".rotation)

func _on_sno_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.teleport($"Map/Teleports/Out/mav".global_position, $"Map/Teleports/Out/mav".rotation)

func _on_wat_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.teleport($"Map/Teleports/Out/bob".global_position, $"Map/Teleports/Out/bob".rotation)

func _on_pea_area_entered(area):
	if area.name == "PlayerArea":
		var player : Character = area.get_parent()
		player.teleport($"Map/Teleports/Out/bow".global_position, $"Map/Teleports/Out/bow".rotation)
