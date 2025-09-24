extends CSGCylinder3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transparency += delta
	if transparency == 1:
		queue_free()
