extends RigidBody3D

@onready var cooldown_timer : Timer = $Cooldown

@export var source : bool = false
@export_enum("throw") var use_type = "throw"
@export var throw_speed : float = 10.0
@export var scene : PackedScene = preload("res://weapons/pets/rubber_duck.tscn")
@export var cooldown : float = 15.0
var replication_number : int = 5
var replication_waves : int = 5
var original : bool = true
var spawn_position : Vector3
var spawn_velocity : Vector3
var shrink : bool = false

func _ready() -> void:
	hide()
	freeze = true
	if not source:
		freeze = false
		show()
	if not original:
		body_entered.disconnect(_on_body_entered)
		$SelfDestruct.start()
		gravity_scale = 0.5
	linear_velocity = Vector3.ZERO
	global_position = spawn_position
	linear_velocity = spawn_velocity
	$Cooldown.wait_time = cooldown

func _physics_process(delta) -> void:
	if shrink:
		scale += -0.5*delta*Vector3.ONE
	if scale.x < 0.05:
		queue_free()

func replicate() -> void:
	for n in range(replication_number):
		var duck = scene.instantiate()
		duck.spawn_position = global_position
		duck.spawn_velocity = get_vector() * 5
		duck.original = false
		duck.rotation = rotation
		get_parent().add_child(duck)
	replication_waves += -1
	if replication_waves == 0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not original:
		return
	if not body.is_class("CharacterBody3D"):
		freeze = true
		hide()
		$CollisionShape3D.disabled = true
		replicate()
		$Replicate.start()

func get_vector() -> Vector3:
	return Vector3(randf_range(-0.15, 0.15), 1, randf_range(-0.15, 0.15)).normalized()

func _on_self_destruct_timeout() -> void:
	shrink = true

func _on_replicate_timeout() -> void:
	replicate()
