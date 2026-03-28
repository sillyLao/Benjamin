extends Control

@onready var camera = $MarginContainer/HBoxContainer/Previsualisation/SubViewportContainer/SubViewport/Camera3D

var selected_weapon = "Blaster1"

func _ready() -> void:
	switch_to_weapon($MarginContainer/HBoxContainer/Selection/ScrollContainer/VBoxContainer/Line1/Blaster1)

func _physics_process(delta) -> void:
	$Node3D/Pivot.rotation.y += delta/2.0

func switch_to_weapon(selection : TextureRect) -> void:
	camera.size = selection.camera_size
	$Node3D/Pivot.get_node(selected_weapon).hide()
	selected_weapon = str(selection.name)
	$Node3D/Pivot.get_node(selected_weapon).show()
	$MarginContainer/HBoxContainer/Description/RichTextLabel.text = selection.description


func _on_ok_pressed():
	get_parent().switch_weapon(selected_weapon)
	hide()
