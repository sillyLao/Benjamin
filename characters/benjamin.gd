extends CharacterBody3D
class_name Character

var map : Node3D
@onready var camera = $Camera3D
@onready var hand = $Camera3D/Hand
@onready var invulnerability_timer : Timer = $Invulnerability
@onready var animation_player = $AnimationPlayer

@export var blaster : Blaster
@export var pet : Node3D

var spawn_node : Node3D
@export_category("Scale")
@export var MIN_SCALE : float = 0.1
@export var MAX_SCALE : float = 1.0
var goal_scale : float = 1.0
@export var SCALE_REGEN : float = 0.01
@export var BONUS_SCALE_REGEN : float = 0.03
@export_category("Movement")
var speed : float = 10.0
@export var BASE_SPEED : float = 10.0
@export var SPEED_MULT : float = 0.6
var jump : float = 7.5
@export var BASE_JUMP : float = 7.5
@export var JUMP_MULT : float = 1.7

var laser_color : Color = Color.WHITE
var is_dead : bool = false
var in_hand : String = "blaster"
@export var invulnerable : bool = true

func _enter_tree():
	$Label3D.text = Global.players_dict[int(name)]["pseudo"]
	set_multiplayer_authority(int(name))

func _ready():
	if is_multiplayer_authority():
		equip()
		#blaster.reparent(hand, false)
		$Sketchfab_Scene.hide()
		$Label3D.hide()
		$Camera3D.make_current()
		laser_color = Global.players_dict[int(name)]["laser_color"]
		UIOverlay.progress_bar.value = 1
		UIOverlay.progress_bar.self_modulate = Color(0.0, 0.7, 0.0)
		Global.current_character = self
		UIOverlay.self_player = self
		UIOverlay.scale_bar.setup(self)

func position_spawn():
	if spawn_node:
		position = spawn_node.position
		rotation = spawn_node.rotation
	print("["+str(multiplayer.get_unique_id())+"] " + str(spawn_node))

func _physics_process(delta):
	var input_dir : Vector2
	if is_multiplayer_authority() and not is_dead:
		input_dir = Input.get_vector("left", "right", "forward", "backward")
		
		
		UIOverlay.progress_bar.value = goal_scale
		if not goal_scale > 1.0:
			goal_scale = clamp(goal_scale + SCALE_REGEN*delta, 0, 1.0)
			
			if not input_dir and is_on_floor():
				goal_scale = clamp(goal_scale + BONUS_SCALE_REGEN*delta, 0, 1.0)
			if goal_scale > 0.6:
				UIOverlay.progress_bar.self_modulate = Color(1.0, 0.7, 0.0).lerp(Color(0.0, 0.7, 0.0), (goal_scale-0.6)*2.5)
			elif goal_scale > 0.3:
				UIOverlay.progress_bar.self_modulate = Color(0.8, 0.0, 0.0).lerp(Color(1.0, 0.7, 0.0), (goal_scale-0.3)*(1/0.3))
			else:
				UIOverlay.progress_bar.self_modulate = Color(0.8, 0.0, 0.0)
			if is_on_ceiling() and is_on_floor() and !invulnerable:
				crushed_too_big()
		scale = Vector3.ONE*lerp(scale.x, goal_scale, 0.2)

func _input(event : InputEvent) -> void:
	if is_multiplayer_authority() and not Global.paused and not is_dead:
		if event.is_action_pressed("use_pet"):
			in_hand = "pet"
		elif  event.is_action_released("use_pet"):
			in_hand = "blaster"
		if event.is_action_pressed("shoot"):
			match in_hand:
				"blaster":
					blaster.shoot()
				"pet":
					use_pet()


@rpc("any_peer", "call_local", "reliable")
func call_laser(id : int, parameters : Array) -> void:
	blaster.create_laser(id, parameters)

func update_ammos(count):
	var string = str(count) + " / " + str(blaster.MAX_AMMOS)
	UIOverlay.ammos.text = string

func _on_feet_box_area_entered(area):
	if is_multiplayer_authority():
		print(area)
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

@rpc("any_peer", "call_remote", "reliable")
func touched(from: int, to: int):
	var node : Character = get_node("../"+str(to))
	var pos = get_node("../"+str(from)).position
	UIOverlay.spawn_hit_pos_indicator(pos, Global.players_dict[from]["laser_color"])
	node.goal_scale -= blaster.SCALE_DAMAGE
	print(goal_scale)
	print(MIN_SCALE)
	if node.goal_scale <= node.MIN_SCALE:
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
	player.get_node("Collisions").disabled = true
	if int(name) == id:
		die()

@rpc("any_peer", "call_local", "reliable")
func ask_for_respawn(id : int):
	get_parent().respawn(id)
	
@rpc("any_peer", "call_local", "reliable")
func respawn_at(pos : String):
	position = get_parent().get_node("Map/Respawns/" + pos).position
	rotation = get_parent().get_node("Map/Respawns/" + pos).rotation
	scale = Vector3.ONE
	goal_scale = 1.0
	invulnerability_timer.start()
	is_dead = false
	respawn_player.rpc(int(name))
	respawn()

@rpc("any_peer", "call_local", "reliable")
func respawn_player(id : int):
	var player = get_parent().get_node(str(id))
	player.show()
	player.get_node("PlayerArea").collision_layer = 2
	player.get_node("Collisions").disabled = false

func _on_respawn_timer_timeout():
	ask_for_respawn.rpc_id(1, int(name))

func die():
	blaster.regain_ammo_timer.paused = true
	invulnerable = true

func respawn():
	blaster.regain_ammo_timer.paused = false
	blaster.regain_ammo_timer.start()
	blaster.ammos = blaster.STARTING_AMMOS
	update_ammos(blaster.ammos)
	UIOverlay.progress_bar.value = 1
	UIOverlay.progress_bar.self_modulate = Color(0.0, 0.7, 0.0)

func equip() -> void:
	equip_weapon()

func equip_weapon():
	#print("[" + str(multiplayer.get_unique_id()) + "]  player : " + str(player) + " | authority : " + str(player.is_multiplayer_authority()))
	var path = load("res://weapons/" + Global.players_dict[int(name)]["weapon"].to_snake_case() + ".tscn")
	var weapon = path.instantiate()
	weapon.player = self
	weapon.authority = name.to_int()
	weapon.name = "Blaster"
	blaster = weapon
	hand.add_child(weapon)
	#weapon.position = Vector3.ZERO

func use_pet() -> void:
	if pet.cooldown_timer.is_stopped():
		pet.cooldown_timer.start()
		var new_pet = pet.duplicate()
		new_pet.spawn_position = hand.global_position
		var v : Vector3 = Vector3.FORWARD.rotated(Vector3(1, 0, 0), camera.rotation.x)
		v = v.rotated(Vector3(0, 1, 0), global_rotation.y) * new_pet.throw_speed
		v = v + velocity
		print(v)
		print(camera.rotation.x)
		new_pet.spawn_velocity = v
		new_pet.source = false
		new_pet.rotation = Vector3(camera.rotation.x, rotation.y, 0)
		map.add_child.call_deferred(new_pet)


func _on_invulnerability_timeout():
	invulnerable = false
