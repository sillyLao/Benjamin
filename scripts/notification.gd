extends Control

@onready var color_rect : ColorRect = $VBoxContainer/HBoxContainer/ColorRect
@onready var v_separator : VSeparator = $VBoxContainer/HBoxContainer/VSeparator
@onready var timer : Timer = $Timer

var mouse_in : bool = false

func _process(_delta):
	color_rect.size_flags_stretch_ratio = (timer.time_left/timer.wait_time)
	v_separator.size_flags_stretch_ratio = 1-(timer.time_left/timer.wait_time)
	if color_rect.size_flags_stretch_ratio == 0:
		queue_free()

func _on_mouse_entered():
	timer.paused = true
	mouse_in = true
func _on_mouse_exited():
	timer.paused = false
	mouse_in = false

func _input(event : InputEvent):
	if mouse_in:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.pressed:
					queue_free()
