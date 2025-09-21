extends Node3D

@onready var player = $Character
var enemy_scene = preload("res://scenes/enemy.tscn")



func _on_timer_timeout():
	var dist = 80
	var angle = randf_range(0, 2*PI)
	var pos = Vector2(dist*cos(angle), dist*sin(angle))
	var new_pos = Vector3(pos.x + player.position.x, 1, pos.y + player.position.z)
	var enemy : CharacterBody3D = enemy_scene.instantiate()
	enemy.position = new_pos
	add_child(enemy)
