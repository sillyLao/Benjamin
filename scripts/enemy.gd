extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var retrecir := false
var player : Node3D

func _ready():
	player = get_node("../Character")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = position.direction_to(player.position)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	look_at(Vector3(player.position.x, position.y, player.position.z))
	move_and_slide()
	
	if retrecir:
		scale = clamp(scale-Vector3(0.2, 0.2, 0.2)*delta, Vector3(0.2, 0.2, 0.2), Vector3.ONE)

func _on_area_3d_area_entered(area):
	if area.name == "BulletArea":
		retrecir = true
		$Timer.start()


func _on_timer_timeout():
	queue_free()
