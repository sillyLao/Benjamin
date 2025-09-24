extends CharacterBody3D

@onready var camera = $Camera3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var bullet_scene = preload("res://scenes/Entities/bullet.tscn")
var laser_scene = preload("res://scenes/Entities/laser_ray.tscn")
var retrecir := false

func _enter_tree():
	set_multiplayer_authority(int(name))

func _ready():
	if is_multiplayer_authority():
		$Sketchfab_Scene.hide()
		$Camera3D.make_current()

func _physics_process(delta):
	if is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		move_and_slide()
		
		if retrecir:
			scale = clamp(scale-Vector3(0.2, 0.2, 0.2)*delta, Vector3(0.1, 0.1, 0.1), Vector3.ONE)
		
		

func _input(event : InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed("shoot"):
			shoot()

func shoot():
	create_laser()
	var hitscan = get_camera_collision()
	if hitscan:
		var collider : Node = hitscan.collider
		if collider.is_class("CharacterBody3D"):
			touched.rpc(int(collider.name))

func get_camera_collision():
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*20
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	return intersection

func create_laser():
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*20
	var laser : CSGCylinder3D = laser_scene.instantiate()
	laser.position = (ray_origin+ray_end)/2
	laser.rotation = Vector3(0, rotation.y+PI/2, camera.rotation.x-PI/2)
	laser.height = 19.5
	get_parent().add_child(laser)

@rpc("any_peer", "call_local", "reliable")
func touched(id : int):
	UIOverlay.spawn_notification({
		"icon" : "res://icon.svg",
		"text" : Global.players_dict[id]["pseudo"] + " a été touché !!",
		"timer" : 1.5
	})

func _on_player_area_area_entered(area):
	if area.name == "EnemyArea":
		if area.get_parent().retrecir == false:
			retrecir = true
