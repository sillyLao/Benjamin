extends RigidBody3D

@onready var cooldown_timer : Timer = $Cooldown

@export var source : bool = false
@export_enum("throw") var use_type = "throw"
@export var throw_speed : float = 15.0
@export var scene : PackedScene = preload("res://weapons/pets/rubber_duck.tscn")
@export var cooldown : float = 1.0
@export var speed : float = 5.0
var activated : bool = false
var spawn_position : Vector3
var spawn_velocity : Vector3
var shrink : bool = false
@export var prey : Character 
var gdelta : float 
var player : Character

func _ready() -> void:
	hide()
	freeze = true
	if not source:
		freeze = false
		show()
		$Activation.start()
	$Cooldown.wait_time = cooldown
	linear_velocity = Vector3.ZERO
	global_position = spawn_position
	linear_velocity = spawn_velocity

func _physics_process(delta):
	gdelta = delta

func _integrate_forces(state) -> void:
	if shrink:
		scale += -0.5*gdelta*Vector3.ONE
	if scale.x < 0.05:
		queue_free()
	if activated and prey:
		state.transform = state.transform.looking_at(prey.position)
		state.transform.origin = state.transform.origin.move_toward(Vector3(prey.position.x, position.y, prey.position.z), speed * gdelta)

#func _on_body_entered(body: Node3D) -> void:
	#if not original:
		#return
	#if not body.is_class("CharacterBody3D"):
		#freeze = true
		#hide()
		#$CollisionShape3D.disabled = true
		#replicate()
		#$Replicate.start()

func _on_self_destruct_timeout() -> void:
	shrink = true


func _on_activation_timeout():
	activated = true
