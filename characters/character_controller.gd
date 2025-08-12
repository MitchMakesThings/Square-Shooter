class_name CharacterController extends CharacterBody3D

var movement_path : PackedVector3Array = []

func _physics_process(delta):
	if len(movement_path) < 1:
		return
	var target_position = movement_path[0]	
	if ((global_position - target_position).length() < .1):
		movement_path.remove_at(0)
		return
	global_position = global_position.lerp(target_position, .1)
	#velocity = (target_position - global_position).normalized() * 300 * delta
	#move_and_slide()
	
