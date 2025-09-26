extends CharacterBody3D

@onready var camera = $Camera3D

const MIN_SCALE = 0.2
const SCALE_REGEN = 0.01
const BONUS_SCALE_REGEN = 0.03
const SCALE_DAMAGE = 0.2
var speed = 10.0
const BASE_SPEED = 10.0
const SPEED_MULT = 0.7
var jump = 7.5
const BASE_JUMP = 7.5
const JUMP_MULT = 1.5
const MAX_AMMOS = 10
const LASER_LENGTH = 150
var ammos = 2
var bullet_scene = preload("res://scenes/Entities/bullet.tscn")
var laser_scene = preload("res://scenes/Entities/laser_ray.tscn")
var is_dead : bool = false
var laser_color : Color = Color.WHITE

func _enter_tree():
	$Label3D.text = Global.players_dict[int(name)]["pseudo"]
	set_multiplayer_authority(int(name))

func _ready():
	if is_multiplayer_authority():
		$gun.reparent($Camera3D)
		$Sketchfab_Scene.hide()
		$Label3D.hide()
		$Camera3D.make_current()
		laser_color = Global.players_dict[int(name)]["laser_color"]
		update_ammos()
		$RegainAmmoTimer.start()
		UIOverlay.scale_bar.value = 1
		UIOverlay.scale_bar.self_modulate = Color(0.0, 0.7, 0.0)

func _physics_process(delta):
	var input_dir
	if is_multiplayer_authority() and not is_dead:
		if not Global.paused:
			# Handle jump.
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				jump = ((1-scale.x)*1/(1-MIN_SCALE)+JUMP_MULT)*BASE_JUMP
				velocity.y = jump

			# Get the input direction and handle the movement/deceleration.
			# As good practice, you should replace UI actions with custom gameplay actions.
			speed = ((scale.x-MIN_SCALE)*(1-MIN_SCALE)/SPEED_MULT+MIN_SCALE)*BASE_SPEED
			input_dir = Input.get_vector("left", "right", "forward", "backward")
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		
		if not ammos == MAX_AMMOS:
			UIOverlay.ammos_progress.value = (1-($RegainAmmoTimer.time_left/$RegainAmmoTimer.wait_time))*100
	
		if not scale.x == 1:
			scale = clamp(scale + Vector3.ONE*SCALE_REGEN*delta, Vector3.ONE*MIN_SCALE, Vector3.ONE)
			if not input_dir and is_on_floor():
				scale = clamp(scale + Vector3.ONE*BONUS_SCALE_REGEN*delta, Vector3.ONE*MIN_SCALE, Vector3.ONE)
			UIOverlay.scale_bar.value = scale.x
			if scale.x > 0.6:
				UIOverlay.scale_bar.self_modulate = Color(1.0, 0.7, 0.0).lerp(Color(0.0, 0.7, 0.0), (scale.x-0.6)*2.5)
			elif scale.x > 0.3:
				UIOverlay.scale_bar.self_modulate = Color(0.8, 0.0, 0.0).lerp(Color(1.0, 0.7, 0.0), (scale.x-0.3)*(1/0.3))
			else:
				UIOverlay.scale_bar.self_modulate = Color(0.8, 0.0, 0.0)
			if is_on_ceiling() and is_on_floor():
				crushed_too_big()

func _input(event : InputEvent) -> void:
	if is_multiplayer_authority() and not Global.paused and not is_dead:
		if event.is_action_pressed("shoot"):
			shoot()

func shoot():
	if ammos:
		if ammos == MAX_AMMOS:
			$RegainAmmoTimer.start()
		ammos += -1
		update_ammos()
		create_laser.rpc(int(name), get_laser_parameters())
		var hitscan = get_camera_collision()
		if hitscan:
			var collider : Node = hitscan.collider
			if collider.name == "PlayerArea": # Player hit
				touched.rpc_id(int(collider.get_parent().name), int(name), int(collider.get_parent().name))
				UIOverlay.animation_player.play("crosshair_hit")
			

func get_camera_collision():
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*LASER_LENGTH
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	new_intersection.collide_with_areas = true
	new_intersection.collision_mask = 1
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	return intersection

func get_laser_parameters() -> Array:
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*LASER_LENGTH
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
	var laser : CSGCylinder3D = laser_scene.instantiate()
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

func _on_regain_ammo_timer_timeout():
	ammos += 1
	update_ammos()
	if not ammos == MAX_AMMOS:
		$RegainAmmoTimer.start()

func die():
	$RegainAmmoTimer.paused = true

func respawn():
	$RegainAmmoTimer.paused = false
	$RegainAmmoTimer.start()
	ammos = 4
	update_ammos()
	UIOverlay.scale_bar.value = 1
	UIOverlay.scale_bar.self_modulate = Color(0.0, 0.7, 0.0)

func update_ammos():
	UIOverlay.ammos.text = str(ammos) + " / " + str(MAX_AMMOS)

func _on_feet_box_area_entered(area):
	if area.name == "PlayerArea":
		var player : CharacterBody3D = area.get_parent()
		if player.scale.x <= scale.x/2.0 and not player == self:
			print("["+str(multiplayer.get_unique_id())+"] " + str(player))
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
