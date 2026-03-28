extends Node3D
class_name Blaster

@export var display : bool = false
var authority : int
var player : Character
@onready var camera : Camera3D
@onready var regain_ammo_timer : Timer = $RegainAmmoTimer

@export_category("Weapon")
@export var MAX_AMMOS : int = 10
@export var SCALE_DAMAGE : float = 0.2
@export var STARTING_AMMOS : int = 2
@export var RELOAD_TIME : float = 0.2
@export var AMMO_REGAIN_TIME : float = 0.6
@export var REGAIN_COOLDOWN : float = 0.5
@export_category("Laser")
@export var LASER_LENGTH : float = 80.0
@export var LASER_SIDES : int = 3
@export var LASER_FALL_ACCEL : float = 0.01
@export var laser_scene = preload("res://weapons/projectiles/laser_ray.tscn")

var ammos : int = 0

func _enter_tree():
	set_multiplayer_authority(authority)

func _ready() -> void:
	if not ammos == MAX_AMMOS:
		$RegainAmmoTimer.start()
	$RegainAmmoTimer.wait_time = AMMO_REGAIN_TIME
	$Reload.wait_time = RELOAD_TIME
	$RegainCooldown.wait_time = REGAIN_COOLDOWN
	if not display and not player:
		player = get_node("../../..")
		player.blaster = self
		
	if player:
		camera = player.camera
		ammos = STARTING_AMMOS
		player.update_ammos(ammos)

func _physics_process(_delta) -> void:
	if not is_multiplayer_authority():
		return
	if not ammos == MAX_AMMOS and not $RegainAmmoTimer.time_left == 0:
		UIOverlay.ammos_progress.value = (1-($RegainAmmoTimer.time_left/$RegainAmmoTimer.wait_time))*100
	else:
		UIOverlay.ammos_progress.value = 0
	if not $Reload.is_stopped():
		UIOverlay.blaster_reload.value = ($Reload.wait_time - $Reload.time_left)/$Reload.wait_time

func _on_regain_ammo_timer_timeout():
	ammos += 1
	if not ammos == MAX_AMMOS:
		$RegainAmmoTimer.start()
	if is_multiplayer_authority():
		player.update_ammos(ammos)

func shoot():
	if not $Reload.is_stopped():
		return
	if ammos:
		player.animation_player.stop()
		player.animation_player.play("shoot")
		$RegainAmmoTimer.paused = true
		$Reload.start()
		$RegainCooldown.start()
		ammos += -1
		player.update_ammos(ammos)
		player.call_laser.rpc(int(player.name), get_laser_parameters())
		var hitscan = get_camera_collision()
		if hitscan:
			var collider : Node = hitscan.collider
			if collider.name == "PlayerArea" and !collider.get_parent().invulnerable: # Player hit
				player.touched.rpc_id(int(collider.get_parent().name), int(player.name), int(collider.get_parent().name))
				UIOverlay.animation_player.play("crosshair_hit")

func create_laser(id : int, parameters : Array) -> void:
	var laser : CSGCylinder3D = laser_scene.instantiate()
	laser.position = (parameters[0]+parameters[1])/2
	laser.rotation = parameters[2]
	laser.height = parameters[0].distance_to(parameters[1])-0.2
	laser.material_override = laser.material.duplicate()
	laser.material_override.albedo_color = Global.players_dict[id]["laser_color"]
	laser.material_override.emission = Global.players_dict[id]["laser_color"]
	laser.sides = LASER_SIDES
	laser.fall_accel = LASER_FALL_ACCEL
	player.get_parent().add_child(laser)

func get_laser_parameters() -> Array:
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*LASER_LENGTH
	var rot = Vector3(0, player.rotation.y+PI/2, camera.rotation.x-PI/2)
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	new_intersection.collide_with_areas = true
	new_intersection.collision_mask = 2
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	if intersection:
		ray_end = intersection.position
	return [ray_origin, ray_end, rot]

func get_camera_collision() -> Dictionary:
	var centre = get_viewport().get_visible_rect().size/2
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre)*LASER_LENGTH
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	new_intersection.collide_with_areas = true
	new_intersection.collision_mask = 2
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	return intersection


func _on_reload_timeout():
	UIOverlay.blaster_reload.value = 1


func _on_regain_cooldown_timeout():
	$RegainAmmoTimer.paused = false
	if $RegainAmmoTimer.is_stopped():
		$RegainAmmoTimer.start()
