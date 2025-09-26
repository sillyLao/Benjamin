extends CSGCylinder3D

func _ready():
	material_override.emission_energy_multiplier = 16

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transparency += delta
	material.emission_energy_multiplier += -delta*8
	if transparency == 1:
		queue_free()
