extends Control

@onready var pb = $ProgressBar
@onready var limit = $ProgressBar/Limit

func setup(chara : CharacterBody3D):
	pb.max_value = chara.MAX_SCALE
	pb.min_value = chara.MIN_SCALE
	#limit.position.y = 334 - 
