extends CSGCylinder3D

var fall : float = 0.0
var fall_accel : float

#func _ready():
	#material_override.emission_energy_multiplier = 16


func _process(delta):
	fall += fall_accel
	position.y += -fall*delta/2
	if not $Timer.time_left:
		transparency += delta
		#material.emission_energy_multiplier += -delta*8
		if transparency == 1:
			queue_free()
