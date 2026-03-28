extends Node

@onready var Chara : CharacterBody3D = get_parent()


func _physics_process(delta) -> void:
	var input_dir : Vector2
	if Chara.is_multiplayer_authority() and not Chara.is_dead:
		var direction : Vector3
		if not Global.paused:
			# Handle jump.
			if Input.is_action_just_pressed("ui_accept") and Chara.is_on_floor():
				Chara.jump = ((1-Chara.scale.x)/(1-Chara.MIN_SCALE)*(Chara.JUMP_MULT-1)+1)*Chara.BASE_JUMP
				Chara.velocity.y = Chara.jump
			
			Chara.speed = ((Chara.scale.x-Chara.MIN_SCALE)*(1-Chara.SPEED_MULT)/(1-Chara.MIN_SCALE)+Chara.SPEED_MULT)*Chara.BASE_SPEED
			input_dir = Input.get_vector("left", "right", "forward", "backward")
			direction = (Chara.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			
		# Add the gravity.
		var fall = 1
		if not Chara.is_on_floor():
			if Chara.velocity.y < 0:
				fall = 1.5
			else:
				fall = 1
			Chara.velocity += Chara.get_gravity() * delta * fall
		if direction:
			if Chara.is_on_floor():
				Chara.velocity.x = lerpf(Chara.velocity.x, direction.x * Chara.speed, 0.2) 
				Chara.velocity.z = lerpf(Chara.velocity.z, direction.z * Chara.speed, 0.2)
			else:
				Chara.velocity.x = lerpf(Chara.velocity.x, direction.x * Chara.speed, 0.03)
				Chara.velocity.z = lerpf(Chara.velocity.z, direction.z * Chara.speed, 0.03)
		else:
			if Chara.is_on_floor():
				Chara.velocity.x = move_toward(Chara.velocity.x, 0, Chara.BASE_SPEED*delta*10)
				Chara.velocity.z = move_toward(Chara.velocity.z, 0, Chara.BASE_SPEED*delta*10)
			else:
				Chara.velocity.x = move_toward(Chara.velocity.x, 0, Chara.BASE_SPEED*delta)
				Chara.velocity.z = move_toward(Chara.velocity.z, 0, Chara.BASE_SPEED*delta)
		Chara.move_and_slide()
