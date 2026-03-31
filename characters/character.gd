extends CharacterBody3D

@onready var camera = $Camera3D

@export var blaster : Node3D

var spawn_node : Node3D
@export var MIN_SCALE : float = 0.2
@export var SCALE_REGEN : float = 0.01
@export var BONUS_SCALE_REGEN : float = 0.03
var SCALE_DAMAGE : float = 0.2
var speed : float = 10.0
@export var BASE_SPEED : float = 10.0
@export var SPEED_MULT : float = 0.6
var jump : float = 7.5
@export var BASE_JUMP : float = 7.5
@export var JUMP_MULT : float = 1.7

var is_dead : bool = false
var laser_color : Color = Color.WHITE

func _enter_tree():
	$Label3D.text = Global.players_dict[int(name)]["pseudo"]
	set_multiplayer_authority(int(name))

func _ready():
	if is_multiplayer_authority():
		$Blaster.reparent($Camera3D)
		$Sketchfab_Scene.hide()
		$Label3D.hide()
		$Camera3D.make_current()
		laser_color = Global.players_dict[int(name)]["laser_color"]
		update_ammos()
		UIOverlay.progress_bar.value = 1
		UIOverlay.progress_bar.self_modulate = Color(0.0, 0.7, 0.0)
		UIOverlay.self_player = self

func position_spawn():
	if spawn_node:
		position = spawn_node.position
		rotation = spawn_node.rotation
	#print("["+str(multiplayer.get_unique_id())+"] " + str(spawn_node))

func _physics_process(delta):
	var input_dir : Vector2
	if is_multiplayer_authority() and not is_dead:
		input_dir = Input.get_vector("left", "right", "forward", "backward")
		
		
		UIOverlay.progress_bar.value = scale.x
		if not scale.x > 0.99:
			scale = clamp(scale + Vector3.ONE*SCALE_REGEN*delta, Vector3.ONE*MIN_SCALE, Vector3.ONE)
			if not input_dir and is_on_floor():
				scale = clamp(scale + Vector3.ONE*BONUS_SCALE_REGEN*delta, Vector3.ONE*MIN_SCALE, Vector3.ONE)
			if scale.x > 0.6:
				UIOverlay.progress_bar.self_modulate = Color(1.0, 0.7, 0.0).lerp(Color(0.0, 0.7, 0.0), (scale.x-0.6)*2.5)
			elif scale.x > 0.3:
				UIOverlay.progress_bar.self_modulate = Color(0.8, 0.0, 0.0).lerp(Color(1.0, 0.7, 0.0), (scale.x-0.3)*(1/0.3))
			else:
				UIOverlay.progress_bar.self_modulate = Color(0.8, 0.0, 0.0)
			if is_on_ceiling() and is_on_floor():
				crushed_too_big()
				#print(scale.x)
			

func _input(event : InputEvent) -> void:
	if is_multiplayer_authority() and not Global.paused and not is_dead:
		if event.is_action_pressed("shoot"):
			blaster.shoot()
			

func get_camera_collision():
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*blaster.LASER_LENGTH
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	new_intersection.collide_with_areas = true
	new_intersection.collision_mask = 1
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	return intersection

func get_laser_parameters() -> Array:
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*blaster.LASER_LENGTH
	var rot = Vector3(0, rotation.y+PI/2, camera.rotation.x-PI/2)
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	new_intersection.collide_with_areas = true
	new_intersection.collision_mask = 1
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	if intersection:
		ray_end = intersection.position
	return [ray_origin, ray_end, rot]

@rpc("any_peer", "call_local", "reliable")
func create_laser(id: int, parameters: Array):
	var laser : CSGCylinder3D = blaster.laser_scene.instantiate()
	laser.position = (parameters[0]+parameters[1])/2
	laser.rotation = parameters[2]
	laser.height = parameters[0].distance_to(parameters[1])-0.2
	laser.material_override = laser.material.duplicate()
	laser.material_override.albedo_color = Global.players_dict[id]["laser_color"]
	laser.material_override.emission = Global.players_dict[id]["laser_color"]
	get_parent().add_child(laser)

@rpc("any_peer", "call_remote", "reliable")
func touched(from: int, to: int):
	var node : CharacterBody3D = get_node("../"+str(to))
	var pos = get_node("../"+str(from)).position
	UIOverlay.spawn_hit_pos_indicator(pos, Global.players_dict[from]["laser_color"])
	node.scale -= Vector3.ONE*SCALE_DAMAGE
	if node.scale.x <= 0.1:
		node.is_dead = true
		UIOverlay.spawn_notification({
			"icon" : "res://icon.svg",
			"text" : "Vous avez été rétréci.e par " + Global.players_dict[from]["pseudo"] + ".",
			"timer" : 3
		})
		killed_someone.rpc_id(from, to, "shrink")
		disappear.rpc(to)
		node.get_node("RespawnTimer").start()
		Global.add_kill_death.rpc(from, to)

@rpc("any_peer", "call_remote", "reliable")
func killed_someone(from: int, method: String):
	var text : String
	match method:
		"shrink":
			text = "Vous avez rétréci " + Global.players_dict[from]["pseudo"] + " !!"
		"crush":
			text = "Vous avez écrasé " + Global.players_dict[from]["pseudo"] + " !!"
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : text,
		"timer" : 3
	})
	UIOverlay.spawn_kill_line.rpc(int(name), from, method)


@rpc("any_peer", "call_local", "reliable")
func disappear(id : int): # is killed
	var player = get_parent().get_node(str(id))
	player.hide()
	player.get_node("PlayerArea").collision_layer = 0
	if int(name) == id:
		die()

@rpc("any_peer", "call_local", "reliable")
func ask_for_respawn(id : int):
	get_parent().respawn(id)
	
@rpc("any_peer", "call_local", "reliable")
func respawn_at(pos : String):
	position = get_parent().get_node("Map/Respawns/" + pos).position
	rotation = get_parent().get_node("Map/Respawns/" + pos).rotation
	is_dead = false
	scale = Vector3.ONE
	respawn_player.rpc(int(name))
	respawn()

@rpc("any_peer", "call_local", "reliable")
func respawn_player(id : int):
	var player = get_parent().get_node(str(id))
	player.show()
	player.get_node("PlayerArea").collision_layer = 1

func _on_respawn_timer_timeout():
	ask_for_respawn.rpc_id(1, int(name))

func die():
	blaster.regain_ammo_timer.paused = true

func respawn():
	blaster.regain_ammo_timer.paused = false
	blaster.regain_ammo_timer.start()
	blaster.ammos = 4
	update_ammos()
	UIOverlay.progress_bar.value = 1
	UIOverlay.progress_bar.self_modulate = Color(0.0, 0.7, 0.0)

func update_ammos():
	UIOverlay.ammos.text = str(blaster.ammos) + " / " + str(blaster.MAX_AMMOS)

func _on_feet_box_area_entered(area):
	if is_multiplayer_authority():
		if area.name == "PlayerArea":
			var player : CharacterBody3D = area.get_parent()
			if player.scale.x <= scale.x/2.0 and not player.name == name:
				crush_player.rpc_id(int(player.name), int(name), int(player.name))

@rpc("any_peer", "call_remote", "reliable")
func crush_player(from: int, to: int):
	var player : CharacterBody3D = get_node("../" + str(to))
	player.is_dead = true
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : "Vous avez été écrasé.e par " + Global.players_dict[from]["pseudo"] + ".",
		"timer" : 3
	})
	killed_someone.rpc_id(from, to, "crush")
	disappear.rpc(to)
	player.get_node("RespawnTimer").start()
	Global.add_kill_death.rpc(from, to)

func crushed_too_big():
	is_dead = true
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : "Vous avez été écrasé.e sous le plafond....",
		"timer" : 3
	})
	disappear.rpc(int(name))
	get_node("RespawnTimer").start()
	Global.add_kill_death.rpc(0, int(name))
	UIOverlay.spawn_kill_line.rpc(0, int(name), "crushed_self")
