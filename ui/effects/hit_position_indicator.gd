extends Control

var pos : Vector3

func _process(delta):
	if not $Timer.time_left:
		modulate.a -= delta
		if modulate.a <= 0:
			queue_free()
