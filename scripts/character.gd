extends CharacterBody3D

@onready var camera = $Camera3D

const SPEED = 10.0
var JUMP_VELOCITY = 7.5
const MAX_AMMOS = 10
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

func _physics_process(delta):
	var input_dir
	if is_multiplayer_authority() and not is_dead:
		if not Global.paused:
			# Handle jump.
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				JUMP_VELOCITY = ((1-scale.x)*1.25+1)*7.5
				velocity.y = JUMP_VELOCITY

			# Get the input direction and handle the movement/deceleration.
			# As good practice, you should replace UI actions with custom gameplay actions.
			input_dir = Input.get_vector("left", "right", "forward", "backward")
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		
		if not ammos == MAX_AMMOS:
			UIOverlay.ammos_progress.value = (1-($RegainAmmoTimer.time_left/$RegainAmmoTimer.wait_time))*100
		
	scale = clamp(scale + Vector3.ONE*0.01*delta, Vector3.ONE*0.1, Vector3.ONE)
	if not input_dir and is_on_floor():
		scale = clamp(scale + Vector3.ONE*0.03*delta, Vector3.ONE*0.2, Vector3.ONE)

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
			

func get_camera_collision():
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*50
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	new_intersection.collide_with_areas = true
	new_intersection.collision_mask = 1
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	return intersection

func get_laser_parameters() -> Array:
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*50
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
	laser.height = parameters[0].distance_to(parameters[1])-0.5
	laser.material.albedo_color = Global.players_dict[id]["laser_color"]
	laser.material.emission = Global.players_dict[id]["laser_color"]
	get_parent().add_child(laser)

@rpc("any_peer", "call_remote", "reliable")
func touched(from: int, to: int):
	#UIOverlay.spawn_notification({
		#"icon" : "res://icon.svg",
		#"text" : Global.players_dict[from]["pseudo"] + " vous a touché !!",
		#"timer" : 1.5
	#})
	var node : CharacterBody3D = get_node("../"+str(to))
	node.scale -= Vector3.ONE*0.2
	if node.scale.x < 0.1:
		node.is_dead = true
		UIOverlay.spawn_notification({
			"icon" : "res://icon.svg",
			"text" : "Vous avez été rétréci par " + Global.players_dict[from]["pseudo"] + ".",
			"timer" : 3
		})
		killed_someone.rpc_id(from, to)
		disappear.rpc(to)
		node.get_node("RespawnTimer").start()

@rpc("any_peer", "call_remote", "reliable")
func killed_someone(from: int):
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : "Vous avez rétréci " + Global.players_dict[from]["pseudo"] + " !!",
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

func update_ammos():
	UIOverlay.ammos.text = str(ammos) + " / " + str(MAX_AMMOS)
