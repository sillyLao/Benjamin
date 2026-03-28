extends TextureRect

@onready var weapon_selection_screen = $"../../../../../../.."

@export_multiline() var description : String
@export var camera_size : float

var mouse_in : bool = false
var click : bool = false
var pressed : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	$Panel.scale = Vector2.ZERO

func _physics_process(delta):
	if mouse_in:
		$Panel.scale = lerp($Panel.scale, Vector2.ONE, delta*20)
	else:
		$Panel.scale = lerp($Panel.scale, Vector2.ZERO, delta*2)

func _input(event):
	if event.is_action_pressed("select"):
		if mouse_in:
			pressed = true
			modulate = Color(0.75, 0.75, 0.75)
	elif event.is_action_released("select"):
		if mouse_in and pressed:
			weapon_selection_screen.switch_to_weapon(self)
			pressed = false
			modulate = Color(1.2, 1.2, 1.2)


func _on_mouse_entered():
	mouse_in = true
	if pressed:
		modulate = Color(0.75, 0.75, 0.75)
	else:
		modulate = Color(1.2, 1.2, 1.2)
func _on_mouse_exited():
	mouse_in = false
	modulate = Color(1.0, 1.0, 1.0)
