extends HBoxContainer

func _process(delta):
	if not $Timer.time_left:
		modulate.a -= delta
		if modulate.a <= 0:
			queue_free()

func _on_timer_timeout():
	pass # Replace with function body.
