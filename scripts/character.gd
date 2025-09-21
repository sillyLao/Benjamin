extends CharacterBody3D

@onready var camera = $Camera3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var bullet_scene = preload("res://scenes/bullet.tscn")
var retrecir := false

func _physics_process(delta):
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
	if event.is_action_pressed("shoot"):
		shoot()

func shoot():
	var bullet:RigidBody3D = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.position = $Camera3D/gun.global_position
	bullet.rotation = Vector3(0.0, rotation.y+PI/2, camera.rotation.x-PI)
	bullet.linear_velocity = Vector3(-sin(rotation.y)*cos(camera.rotation.x), sin(camera.rotation.x), -cos(rotation.y)*cos(camera.rotation.x))*30

func _on_player_area_area_entered(area):
	if area.name == "EnemyArea":
		if area.get_parent().retrecir == false:
			retrecir = true
